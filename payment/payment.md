# Payment

## Banco Santander

### Código da carteira

1 = ELETRÔNICA COM REGISTRO
3 = CAUCIONADA ELETRÔNICA
4 = COBRANÇA SEM REGISTRO
5 = RÁPIDA COM REGISTRO - (BLOQUETE EMITIDO PELO CLIENTE)
6 = CAUCIONADA RAPIDA
7 = DESCONTADA ELETRÔNICA

### Especie de documento

1 = DUPLICATA
2 = NOTA PROMISSÓRIA
3 = APÓLICE / NOTA DE SEGURO
5 = RECIBO
6 = DUPLICATA DE SERVIÇO
7 = LETRA DE CAMBIO

### Instruções

00 = NÃO HÁ INSTRUÇÕES
02 = BAIXAR APÓS QUINZE DIAS DO VENCIMENTO
03 = BAIXAR APÓS 30 DIAS DO VENCIMENTO
04 = NÃO BAIXAR
06 = PROTESTAR (VIDE POSIÇÃO392/393)
07 = NÃO PROTESTAR
08 = NÃO COBRAR JUROS DE MORA

## Banco Sicoob

### Número do contrato

O que é ?
precisa ter esse campo a mais em conta_banco.rb ?

### Codigo Beneficiario

Quais suas possíveis variáveis ?
pode ser subistiuida ?

### Número do bordeiro

O que é ?
precisa ter esse campo a mais em conta_banco.rb ?

### Revisar instruções do Sicoob

instruções de prazo ocorrencia (pagamento...)

## Banco sicredi

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

