# Payment

## Banco' sicredi

### validar campos que não foram ainda revisados

* byte_idt (o que é?)
* nosso número (como deve ser construido?)

## Ver o banco santander

### o codigo de barras dele está desatualizado

```
foi preciso tirar um digito (9 no inicio) para poder gerar os boletos com codigo de barras
```

* Aguardar documentação para realizar as alterações devidas

## Metaprogramação

### Criar metodo para gerar os set's acrescentando zeros a esquerda

* Este metodo é muito usado em boletos

## Validar carteira do HSBC

* quais carteiras existem ?
* possui numero e letras ?

### Nosso número hoje só reconhece carteiras por letras

* CNR
* CSB

## Validar numero do documento da caixa (sequencia é a mesma situação)
  * na Payment está que só pode ter 15 digitos
  * devo somente reiniciar como a sequencia?
  * ...

## Validar variação do banestes

