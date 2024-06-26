--drop table if exists livros cascade;
--drop table if exists emprestimos cascade;

create table livros (
	bookId SERIAL primary key,
	titulo text not null,
	autor text not null,
	ano_publicado int,
	disponivel boolean default true
);

create or replace procedure cadastrar_livro (
  title text,
  autor_livro text,
  ano int)
language plpgsql
as $$
begin
  insert into livros (titulo, autor, ano_publicado) values (title,autor_livro,ano);
end;$$;

-- cadastro de exemplos de livros 
call cadastrar_livro('Jurassic Park','Michael Crichton',1990);
call cadastrar_livro('Lost World','Michael Crichton',1995);
call cadastrar_livro('Frankenstein','Mary Shelly',1818);

create table emprestimos (
	id_emprestimo SERIAL primary key,
	livroId int references livros (bookId),
	data_emprestimo date not null,
	data_devolucao date
);

create or replace procedure atualizar_titulo_livro (
  id_livro integer,
  new_title text)
language plpgsql
as $$
begin
  update livros set titulo = new_title where bookId = id_livro;
end;$$;

-- Chamando a procedure atualizar_titulo_livro
call atualizar_titulo_livro(1, 'Shazam');

create or replace procedure atualizar_ano_livro (
  id_livro integer,
  new_year int)
language plpgsql
as $$
begin
  update livros set ano_publicado = new_year where bookId = id_livro;
end;$$;

-- Chamando a procedure atualizar_ano_livro
call atualizar_ano_livro(1, 2015);

-- procedure de consulta de livro
create or replace procedure consultar_livro (
  id_livro integer,
  out bookId integer,
  out titulo text,
  out autor text,
  out ano_publicado int,
  out disponivel boolean)
language plpgsql
as $$
begin
  select l.bookId, l.titulo, l.autor, l.ano_publicado, l.disponivel
  into bookId, titulo, autor, ano_publicado, disponivel
  from livros l
  where l.bookId = id_livro;
end;$$;

-- chamada de consultar_livro
do $$
declare
  v_bookId integer;
  v_titulo text;
  v_autor text;
  v_ano_publicado int;
  v_disponivel boolean;
begin
  call consultar_livro(1, v_bookId, v_titulo, v_autor, v_ano_publicado, v_disponivel);
  raise notice 'Book ID: %, Title: %, Author: %, Year: %, Available: %', v_bookId, v_titulo, v_autor, v_ano_publicado, v_disponivel;
end;$$;

-- procedure de remoção de livros
create or replace procedure remover_livro (
  id_livro integer)
language plpgsql
as $$
begin
  delete from livros where bookId = id_livro;
end;$$;

-- mostrando os livros restantes depois de apagar o de id=1
call remover_livro(1);
select * from livros;

create or replace procedure realizar_emprestimo (
  id_livro integer,
  data_emprestimo date)
language plpgsql
as $$
begin 
  if (select disponivel from livros where bookId = id_livro) then 
    insert into emprestimos (livroId, data_emprestimo) values (id_livro, data_emprestimo);
    update livros set disponivel = false where bookId = id_livro;
  end if;
end;$$;

--criação dos triggers
create or replace function registro_disponivel()
returns trigger
language plpgsql
as $registro_disponivel$
begin 
  new.disponivel := false;
  return new;
end;$registro_disponivel$;

create or replace trigger registrar
after update on livros
for each row 
when (old.disponivel is distinct from new.disponivel)
execute function registro_disponivel();

select * from livros;
select * from emprestimos;

-- Chamando a procedure realizar_emprestimo
call realizar_emprestimo(2, current_date);

select * from emprestimos;
select * from livros where disponivel = false;
