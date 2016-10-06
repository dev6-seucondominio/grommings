----   Resolvidos -------

---- Tarefas em execução ----

-----------------------------------------

Estudar sobre
  ACID

Padrão REPEATABLE READ -> READ COMMITTED
  Quando lermos os valores daquele mesmo objeto, sempre leremos os mesmos valores
    indepente de alguem ter alterado ele

SET [GLOBAL | SESSION] TRANSACTION
    transaction_characteristic [, transaction_characteristic] ...

transaction_characteristic:
    ISOLATION LEVEL level
  | READ WRITE
  | READ ONLY

level:
  REPEATABLE READ <- padrão rails
  READ COMMITTED
  READ UNCOMMITTED
  SERIALIZABLE
