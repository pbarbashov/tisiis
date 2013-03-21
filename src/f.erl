-module(f).
-export([start/0, conductor/2, spawn_phils/1, philosopher/1]).
-define(PHILS_QUANTITY,5).
%-include("fphils.hrl").

start() ->
	random:seed(now()),
	register(conductor,spawn(?MODULE, conductor, [ [],100000])),
	io:format("Conductor process successfully started!~n",[]),
	spawn_phils(1),
	ok.

spawn_phils(?PHILS_QUANTITY+1) ->
	%io:format("Philospher processes successfully started!~n",[]),
	ok;
spawn_phils(Phil_num) ->
	Reg_atom = list_to_atom("philosopher" ++ integer_to_list(Phil_num)),
	register(Reg_atom,spawn(?MODULE, philosopher, [Phil_num])),
	io:format("~p process successfully started!~n",[Reg_atom]),
	spawn_phils(Phil_num + 1).


philosopher(Index) ->
	%io:format("1~n",[]),
	philosopher_thinking(Index),
	%io:format("2~n",[]),
	philosopher_hungry(Index,0),
	%io:format("3~n",[]),
	philosopher_eating(Index),
	%io:format("4~n",[]),
	return_forks(Index),
	%io:format("5~n",[]),
	philosopher(Index).

philosopher_thinking(Index) ->
	io:format("philospher~p is thinking!~n",[Index]),
	timer:sleep(random:uniform( 5 ) - 1 ).

philosopher_hungry(_, 1) ->
	ok;
philosopher_hungry(Index, 0) ->
	%io:format("philospher~p is hungry and tries to get left fork!~n",[Index]),
	conductor ! {get_left_fork, Index},		
	receive
		left_fork_busy ->
			timer:sleep(random:uniform( 2 ) - 1 ),	
			Has_left = 0;
		left_fork_free ->
			io:format("philospher~p got left fork!~n",[Index]),
			get_right_fork(Index,0),
			Has_left = 1			
	end,
	philosopher_hungry(Index, Has_left).
	
	
get_right_fork(_, 1) ->
	ok;	
get_right_fork(Index, 0) ->
	%io:format("philospher~p is hungry and tries to get right fork!~n",[Index]),
	conductor ! {get_right_fork, Index},
	receive
		right_fork_busy ->
			timer:sleep(random:uniform( 2 ) - 1 ),	
			Has_right = 0;
		right_fork_free ->
			io:format("philospher~p got right fork!~n",[Index]),
			Has_right = 1	
	end,
	get_right_fork(Index, Has_right).
	


philosopher_eating(Index) ->
	io:format("philospher~p is eating!~n",[Index]),
	timer:sleep(random:uniform( 5 ) - 1 ).

return_forks(Index) ->
	io:format("philospher~p returning forks!~n",[Index]), 
	conductor ! {ret_forks, Index}.

conductor(_, 0) ->
	kill_philosophers(1),
	io:format("Conductor stopped executing and exits!~n",[]),
	ok;
conductor(Busy_forks_list, Ticks) ->
	receive
		{get_left_fork, Index} ->
			Phil_reg_name = list_to_atom("philosopher" ++ integer_to_list(Index)),
			case (length(Busy_forks_list) == 4)  or (lists:member(Index, Busy_forks_list)) of
				true ->
					Phil_reg_name ! left_fork_busy,
					New_Busy_list = Busy_forks_list;
			   	false -> 
					New_Busy_list = Busy_forks_list ++ [Index],
					Phil_reg_name ! left_fork_free	
			end;	   
		{get_right_fork, Index} ->
			Phil_reg_name = list_to_atom("philosopher" ++ integer_to_list(Index)),
			case lists:member(Index rem ?PHILS_QUANTITY + 1, Busy_forks_list) of
				true ->
					Phil_reg_name ! right_fork_busy,
					New_Busy_list = Busy_forks_list;
			   	false -> 
					New_Busy_list = Busy_forks_list ++ [Index rem ?PHILS_QUANTITY + 1],
					Phil_reg_name ! right_fork_free
			end;	   
		{ret_forks, Index} -> 
	%io:format("~p~n",[Busy_forks_list]),
	New_Busy_list = lists:delete(Index rem ?PHILS_QUANTITY + 1,(lists:delete(Index,Busy_forks_list)))		
	%io:format("~p~n",[New_Busy_list])	
	end,
	conductor(New_Busy_list, Ticks - 1).
	


kill_philosophers(?PHILS_QUANTITY+1) ->
	io:format("philospher processes successfully closed!~n",[]),
	ok;
kill_philosophers(Index) ->
	io:format("philospher~p process successfully closed!~n",[Index]),
	exit(whereis(list_to_atom("philosopher" ++ integer_to_list(Index))),time_out),
	kill_philosophers(Index+1).
