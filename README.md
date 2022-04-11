# ExBanking
**It is a basic banking application with OTP and Elixir**

There is no database.All of state is stored in process memory.Each user represented as a process.A user can have any number of different currency account.

Supported operations:
  * create_user
  * get_balance
  * deposit 
  * withdraw
  * send

There are two different implemantations in branches.
* [ets](https://github.com/altuntasfatih/ExBanking/tree/ets)

  Process discovery and load balancing are carried out using custom registry implementation.

  ` @type process_registry ::
          {key :: String.t(), pid :: pid(), operation_count :: non_neg_integer()} `

  process_registry.t() is stored in ets table

  Custom registry is not very easy way to implement. There are more edge cases and also it causes more coupling between modules so I did not like it too much.   

* [mailbox](https://github.com/altuntasfatih/ExBanking/tree/mailbox)

  Process discovery is carrid out using Local Registry.Load balancing is carrid out by a Mailbox.size(Process.info(:message_queue_len)).

  It is very easy way to learn how many messages are in the mailbox. With that info, I have implemented load-balancing easily without creating too much   coupling. Before any operation, It checks that value to decide whether do or not.
  Although it is easy to implement, I am not sure that information is %100 is correct. I think that it might be outdated :)


Main branch is same mailbox.

