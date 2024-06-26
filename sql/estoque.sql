-- criação das tabelas
-- lembre-se o formato DATE do sql é : ano/mes/dia
CREATE TABLE produtos (
  id_produto serial primary key, 
  nome text not null,
  quantidade_estoque integer not null,
  preco decimal not null
);

create table vendas (
  id_venda serial primary key,
  produto_id serial references produtos (id_produto),
  quantidade integer not null,
  data_venda date not null default current_date
);

create table alertas (
  mensagem text not null,
  hora_alerta time not null default current_time
);

-- criação de procedures
create or replace procedure inserir_produto (
  nome text, quantidade integer, preco decimal)
language plpgsql
as $$
begin
  insert into produtos (nome, quantidade_estoque, preco)
  values (nome, quantidade, preco);
end;$$;

-- definindo as colunas como r e percorrendo \ 
-- elas até achar um valor delas que coincida \ 
-- com o valor de parametro
create or replace procedure consultar_produto (
  name text)
language plpgsql
as $$
declare
  r produtos%rowtype;
begin
  for r in select * from produtos where nome = name
  loop
    raise notice '%', row_to_json(r);
  end loop;
end;$$;

create or replace procedure atualizar_produto (
  id_product integer, preco_decimal decimal, name text, quantidade integer)
language plpgsql
as $$
begin
  if preco_decimal is not null then
    update produtos set preco = preco_decimal where id_produto = id_product;
  end if;
  if name is not null then
    update produtos set nome = name where id_produto = id_product;
  end if;
  if quantidade is not null then
    update produtos set quantidade_estoque = quantidade where id_produto = id_product;
  end if;
end;$$;


-- Criação da procedure para apagar produtos
create or replace procedure apagar_produto(id_product integer)
language plpgsql
as $$
declare
  v_count integer;
begin
  select count(*) into v_count
  from vendas
  where produto_id = id_product;
  
  -- se a quantidade em estoque for 0
  if v_count > 0 then
    raise notice 'o produto já foi vendido e não pode ser apagado.';
  else
    -- se o produto não foi vendido, apagar o produto
    delete from produtos
    where id_produto = id_product;
    raise notice 'produto apagado com sucesso.';
  end if;
end;$$;

create or replace procedure registrar_venda(
  produto_id integer, quantidade integer, data_venda date)
language plpgsql
as $$
declare
  estoque_atual integer;
begin
  begin
    select p.quantidade_estoque into estoque_atual
    from produtos p
    where p.id_produto = produto_id
    for update;

    -- verificar se a quantidade em estoque é suficiente
    if estoque_atual >= quantidade then
      update produtos 
      set quantidade_estoque = quantidade_estoque - quantidade 
      where id_produto = produto_id;

      insert into vendas (produto_id, quantidade, data_venda)
      values (produto_id, quantidade, data_venda);

      commit;
      raise notice 'venda realizada!';
    else
      -- se a quantidade em estoque não for suficiente, ajustar a quantidade vendida
      update produtos 
      set quantidade_estoque = 0 
      where id_produto = produto_id;

      -- registrar a venda com a quantidade máxima disponível
      insert into vendas (produto_id, quantidade, data_venda)
      values (produto_id, estoque_atual, data_venda);

      commit;
      raise notice 'o estoque atualmente está vazio. venda parcial realizada.';
    end if;
  end;
end;$$;

-- criação de triggers 
create or replace function alertar() 
   returns trigger 
   language plpgsql
as $alertar$
begin
    if new.quantidade_estoque <= 20 then
      insert into alertas values ('alerta de estoque!',now());
      raise notice 'o estoque precisa ser reabastecido.';
    end if;
    return new;
end;
$alertar$;

create or replace trigger alertar_estoque
after update on produtos
for each row execute procedure alertar();

-- seleção das tabelas
call inserir_produto('pao', 50, 0.50);
call atualizar_produto(1, 4, 'pão', 21);
call consultar_produto('pão');
select * from produtos;
call registrar_venda(1, 15, '2024-05-15');
call apagar_produto(1);
call registrar_venda(1, 30, '2024-05-16');
\echo novos produtos
select * from vendas;
select * from produtos; 
--select * from alertas;
