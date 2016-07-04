# Preparação para o acordo

## Migrates

### Adicionar campos em financeiro_parcelas

* type (STI)

```
scg migration AddTypeInFinanceiroParcelador
```

```ruby
class AddTypeInFinanceiroParcelador < ActiveRecord::Migration
  def change
    add_column :financeiro_parceladores, :type, :string #, null: false # STI

    add_index :financeiro_parceladores, :type
  end
end
```

### Atualizar campos type em parcelador

```
scg migration UpdateTypeInParceladores
```

```ruby
class UpdateTypeInParceladores < ActiveRecord::Migration
  def up
    Financeiro::Parcelador.all.each do |parcelador|
      parcelador.update(type: 'Financeiro::Repeticao')
    end
  end

  def down
    Financeiro::Parcelador.all.each do |parcelador|
      parcelador.update(type: nil)
    end
  end
end
```

### Modificar a tabela financeiro_parcelador

* type (tem que ter null false)

```
scg migration ChangeTypeNullInParceladores
```

```ruby
class ChangeTypeNullInParceladores < ActiveRecord::Migration
  def up
    change_column_null :financeiro_parceladores, :type, false
  end

  def down
    change_column_null :financeiro_parceladores, :type, true
  end
end

```

### Modificar a tabela financeiro_parcelador

* periodo (Acordo não possui)

```
scg migration RemoveNullFalseOfPeriodoInParcelador
```

```ruby
class RemoveNullFalseOfPeriodoInParcelador < ActiveRecord::Migration
  def up
    change_column_null :financeiro_parceladores, :periodo, true
  end

  def down
    change_column_null :financeiro_parceladores, :periodo, false
  end
end
```

### Modificar a tabela financeiro_cobrancas

* cancelada_por_acordo_em (Cobranca gerada acordo)

```
scg migration AddCanceladaPorAcordoEmInCobrancas
```

```ruby
class AddCanceladaPorAcordoEmInCobrancas < ActiveRecord::Migration
  def change
    add_column :financeiro_cobrancas, :cancelada_por_acordo_em, :date

    add_index :financeiro_cobrancas, :cancelada_por_acordo_em
  end
end
```

## Cobranca

### Alterações

#### Acrescentar parceladores na instancia TABLES

file: app/models/financeiro/cobranca.rb

```ruby
module Financeiro
  # no docs
  class Cobranca < ActiveRecord::Base
    set service: ::Financeiro::CobrancasService,
        model_composicao: ::Financeiro::Composicao

    ...

    TABLES = {
      ...
      parceladores:       ::Financeiro::Parcelador.table_name
      ...
    }.freeze
    ...
  end
end
```

#### Acrescentar preload de parcelador no scope de buscar

file: app/models/financeiro/cobranca.rb

```ruby
module Financeiro
  # no docs
  class Cobranca < ActiveRecord::Base
    set service: ::Financeiro::CobrancasService,
        model_composicao: ::Financeiro::Composicao

    ...

    scope :buscar, lambda { |filtro|
      ...
      scoped = scoped.preload(:unidade, :pagador, :parcelador)
      ...
    }
    ...
  end
end
```

### Adicionar

#### Adicionar metodo 'persistida?'

```ruby
module Financeiro
  # no docs
  class Cobranca < ActiveRecord::Base
    set service: ::Financeiro::CobrancasService,
        model_composicao: ::Financeiro::Composicao

    ...
    def persistida?
      # rescue usado porque foi usado metodos select em muitos lugares,
      #  o que não incluem o origem, caso isso acontecer, estamos considerando
      #  como true (validar)
      origem != 'repeticao' rescue true
    end
    ...
  end
end
```

#### Adicionar metodo id (sobrescrever do ActiveRecord) para tratar os ghosts

file: app/models/financeiro/cobranca.rb

```ruby
module Financeiro
  # no docs
  class Cobranca < ActiveRecord::Base
    set service: ::Financeiro::CobrancasService,
        model_composicao: ::Financeiro::Composicao

    ...

    def id
      return super if persistida? # ghost de repetição

      "#{super}:#{parcela}"
    end

    ...
  end
end
```

## STI

### Esquema do STI

```
Para uma repetição mais limpa para as futuras classes que incluiram no STI,
é sugerivel usar Financeiro::Repeticao ao invés de Financeiro::Parcelador (como usado em cobranca)
```

* Financeiro::Parcelador
    * Acordo
    * Repeticao
    * ...

### Alerações

#### Alterando a relação de parcelador em cobranca (class_name)

file: app/models/financeiro/cobranca.rb

```ruby
module Financeiro
  # no docs
  class Cobranca < ActiveRecord::Base
    ...

    belongs_to :parcelador, class_name: 'Financeiro::Repeticao',
                            foreign_key: :parcelador_id

    ...
  end
end
```

#### Alterando a forma de ser chamada o parcelador em serviços

file: app/services/financeiro/cobrancas_service.rb

```ruby
module Financeiro
  # no docs
  class CobrancasService
    ...
    def self.set_parcelador_attributes(cobranca, parcelador)
      ...
        ...
        cobranca.parcelador = ::Financeiro::Repeticao.create!(attrs)
        ...
      ...
    end
    ...
  end
end
```

#### Alterando o model Parcelador

```
Alteração para realizar modificações no type
```

file: app/models/financeiro/parcelador.rb

```ruby
module Financeiro
  # No-docs
  class Parcelador < ActiveRecord::Base
    ...

    def self.attributes_protected_by_default
      # bug rails 4.1 que nulifica os types quando setados em params
      super - [inheritance_column]
    end
  end
end
```

### Adicionar models

file: app/models/financeiro/acordo.rb

```ruby
module Financeiro
  class Acordo < Parcelador
  end
end

```

file: app/models/financeiro/repeticao.rb

```ruby
module Financeiro
  class Repeticao < Parcelador
  end
end
```

### Adicionar serviços

file: app/services/financeiro/acordos_service.rb

```ruby
- parametros usados para o teste

opts = {
  cliente: Condominio.find(2),
  user: User.find(1)
}

params = {
  titulo: 'Acordo',
  mes_referencia: '2016-06-01',
  parcela_qtd: 7,
  cobranca_ids: [
    152, 153, 154
  ],
  vencimentos: [
    { parcela: 1, data: '2016-06-28' },
    { parcela: 2, data: '2016-07-28' },
    { parcela: 3, data: '2016-08-28' },
    { parcela: 4, data: '2016-09-28' },
    { parcela: 5, data: '2016-10-28' },
    { parcela: 6, data: '2016-11-28' },
    { parcela: 7, data: '2016-12-28' }
  ]
}
```

```ruby
module Financeiro
  # no docs
  class AcordosService
    set acl:   ::Financeiro::PermissoesService,
        model: ::Financeiro::Acordo

  end
end
```

#### Adicionar gerar_cobrancas_de_acordo em AcordosService

```
Aqui irá gerar todas as cobranças referentes as cobranças marcadas para serem 'acordadas'.
```

file: app/services/financeiro/acordos_service.rb

```ruby
module Financeiro
  # no docs
  class AcordosService
    set acl:   ::Financeiro::PermissoesService,
        model: ::Financeiro::Acordo

    ...

    # private

    def self.gerar_cobrancas_de_acordo(params)
      cobrancas_ids = params.delete(:cobranca_ids) || []
      cobranca_vencimentos = params.delete(:vencimentos) || []
      params[:unidades_pagadores] = [
        {
          id: 26,
          type: "Financeiro::Pessoa"
        }
      ]

      cobrancas = ::Financeiro::Cobranca.where(id: cobrancas_ids)

      params[:composicoes] = { creditos: [], debitos: [] }
      proc_comp = Proc.new do |comp|
        {
          titulo: comp.titulo,
          plano_conta_id: comp.plano_conta_id,
          valor: comp.valor,
          type: comp.type
        }
      end

      cobrancas.each do |cob|
        creditos = cob.composicoes.reject(&:debito?)
        debitos  = cob.composicoes.select(&:debito?)

        params[:composicoes][:creditos] << creditos.map(&proc_comp) if creditos.any?
        params[:composicoes][:debitos] << debitos.map(&proc_comp) if debitos.any?
      end
      params[:composicoes][:creditos].flatten!
      params[:composicoes][:debitos].flatten!

      cobrancas_acordadas = []
      for vencimento in cobranca_vencimentos
        attrs = params.merge(
          parcela: vencimento[:parcela],
          vencimento: vencimento[:data]
        )

        cobrancas_acordadas << attrs
      end

      [cobrancas_acordadas, cobrancas_ids]
    end
    private_class_method :gerar_cobrancas_de_acordo
  end
end
```

```
Não esquecer que as composições aqui geradas estão com o total de todas as cobranças, mas deve ser a divisão da soma do tal.
```

#### Adicionar create em AcordosService

```
Aqui irá gerar um acordo referente as cobranças marcadas para serem 'acordadas'.
```

file: app/services/financeiro/acordos_service.rb

```ruby
module Financeiro
  # no docs
  class AcordosService
    set acl:   ::Financeiro::PermissoesService,
        model: ::Financeiro::Acordo

    def self.create(opts, params)
      cliente, user = opts.values_at(:cliente, :user)
      return :unauthorized unless acl.gerencia_cobrancas?(cliente, user)

      errors      = []
      success_ids = []
      status      = nil
      ActiveRecord::Base.transaction do
        acordo = model.new(cliente_id: cliente.id)
        return [:errors, [], acordo.errors] unless acordo.save

        cobrancas_para_acordo = ::Financeiro::Cobranca.do_cliente(cliente)
                                                      .find(params[:cobranca_ids])

        return unless cobrancas_para_acordo.map(&:lock!)

        cobrancas_acordadas, cobranca_ids = gerar_cobrancas_de_acordo(params)

        cobrancas_acordadas.each do |cobranca_acordada|
          status, cobranca, errors = ::Financeiro::CobrancasService.create(
            opts, cobranca_acordada
          )

          unless !errors.any? && status == :authorized
            return raise ActiveRecord::Rollback
          end

          # serviço retorna mais de uma cobrança
          cobranca.update_all(parcelador_id: acordo.id)

          cobrancas_para_acordo.map do |cob|
            cob.update(cancelada_por_acordo_em: Time.zone.now)
          end

          create_log :criou, acordo.id, opts, acordo.to_frontend_obj
          success_ids << cobranca.map(&:id)
        end
      end

      [status, success_ids, errors]
    end

    ...
  end
end
```

## Scopes

### Adicionar scope em cobrança

```ruby
module Financeiro
  # no docs
  class Cobranca < ActiveRecord::Base
    set service: ::Financeiro::CobrancasService,
        model_composicao: ::Financeiro::Composicao

    ...

    scope :sem_cancelada_por_acordos, lambda {
      where("#{table_name}.cancelada_por_acordo_em IS NULL")
    }

    ...
  end
end
```

### Alterar scope buscar de cobranca

```
Inicialmente será para não listar os cobranças que geraram acordos
```

```ruby
module Financeiro
  # no docs
  class Cobranca < ActiveRecord::Base
    set service: ::Financeiro::CobrancasService,
        model_composicao: ::Financeiro::Composicao

    ...

    scope :buscar, lambda { |filtro|
      ...

      scoped = scoped.sem_cancelada_por_acordos
      ...
    }
    ...
  end
end
```

## Relacionamentos

### Adicionar relacionamento com a cobranca

```ruby
module Financeiro
  # no docs
  class Cobranca < ActiveRecord::Base
    set service: ::Financeiro::CobrancasService,
        model_composicao: ::Financeiro::Composicao

    ...

    belongs_to :acordo, class_name: 'Financeiro::Acordo',
                        foreign_key: :parcelador_id

    ...
  end
end
```
