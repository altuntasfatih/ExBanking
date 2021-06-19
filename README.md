# ExBanking
**It is a simple banking OTP application on elixir**

There is no database.All of state is stored in process memory.Each user represented as a process.A user can have any number of different currency account.

Supported operations:
  * create_user
  * get_balance
  * deposit 
  * withdraw
  * send
