# ExBanking
**It is a simple banking OTP application with Elixir**

There is no database.All of state is stored in process memory.Each user represented as a process.A user can have any number of different currency account.

Supported operations:
  * create_user
  * get_balance
  * deposit 
  * withdraw
  * send

There are two different implemantations in branches.
 * [counter-based-load-balancer](https://github.com/altuntasfatih/ExBanking/tree/counter-based-load-balancer)

   Process discovery is carrid out using Ets.

   Load balancing is carrid out by a counter on Ets.

 * [mailbox-size-based-load-balancer](https://github.com/altuntasfatih/ExBanking/tree/mailbox-size-based-load-balancer)

   Process discovery is carrid out using Registry.

   Load balancing is carrid out by a Mailbox.size(Process.info(:message_queue_len))

 * main branch is same counter-based-load-balancer
