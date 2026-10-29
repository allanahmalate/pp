:- encoding(utf8).
:- ensure_loaded('dados.pl').

% Sessão do utilizador logado (máximo 1 por execução)
:- dynamic sessao_atual/1.
sessao_atual(nenhum).

% ID generation: max_id(+Predicate, -MaxId) or next_id
max_id(FunctorArity, Max) :-
    findall(ID2, (FunctorArity, arg(1, FunctorArity, ID2)), IDs),
    (   IDs = [] -> Max = 0
    ;   max_list(IDs, Max)
    ).

next_id(FunctorArity, NextID) :-
    max_id(FunctorArity, Max),
    NextID is Max + 1.

% ========== F1: Fornecedores ==========
registar_fornecedor(Nome, Tipo, Contacto) :-
    next_id(fornecedor(ID,_,_,_), ID),
    assertz(fornecedor(ID, Nome, Tipo, Contacto)),
    format('Fornecedor "~w" registado com ID ~w.~n', [Nome, ID]).

listar_fornecedores :-
    findall(fornecedor(Id, Nome, Tipo, Contacto),
            fornecedor(Id, Nome, Tipo, Contacto),
            Fs),
    sort(Fs, Sorted),
    format('===== FORNECEDORES =====~n'),
    forall(member(X, Sorted), (X = fornecedor(Id, Nome, Tipo, Contacto), format('ID:~w | Nome:~w | Tipo:~w | Contato:~w~n', [Id, Nome, Tipo, Contacto]))).

% ========== F2: Produtos ==========
registar_produto(Nome, Tipo, Preco, FornecedorId) :-
    next_id(produto(ID,_,_,_,_,_), ID),
    assertz(produto(ID, Nome, Tipo, Preco, 0, FornecedorId)),
    format('Produto "~w" registado com ID ~w.~n', [Nome, ID]).

listar_produtos :-
    findall(produto(Id, Nome, Tipo, Preco, Stock, FornecId),
            produto(Id, Nome, Tipo, Preco, Stock, FornecId),
            Ps),
    sort(Ps, Sorted),
    format('===== CATALOGO DE PRODUTOS =====~n'),
    forall(member(X, Sorted), (X = produto(Id, Nome, Tipo, Preco, Stock, FornecId), print_produto(Id, Nome, Tipo, Preco, Stock, FornecId))).

print_produto(Id, Nome, Tipo, Preco, Stock, FornecId) :-
    atom_concat(Preco, ' MZN', PrecoMzn),
    (   fornecedor(FornecId, ForNome, _, _)
    ->   FornecedorName = ForNome
    ;   FornecedorName = '<??>'
    ),
    format('ID:~w | ~-24w | ~-12w | ~-11w | Stock:~w | Fornecedor:~w~n',
           [Id, Nome, Tipo, PrecoMzn, Stock, FornecedorName]).

% ========== F3: Culturas ==========
registar_cultura(Nome, Variedade) :-
    next_id(cultura(ID,_,_), ID),
    assertz(cultura(ID, Nome, Variedade)),
    format('Cultura "~w" registada com ID ~w.~n', [Nome, ID]).

listar_culturas :-
    findall(cultura(Id, Nome, Variedade),
            cultura(Id, Nome, Variedade),
            Cs),
    sort(Cs, Sorted),
    format('===== CULTURAS =====~n'),
    forall(member(X, Sorted), (X = cultura(Id, Nome, Variedade), format('ID:~w | Nome:~w | Variedade:~w~n', [Id, Nome, Variedade]))).

% ========== F4: Campanhas ==========
registar_campanha(Ano, CulturaId, AreaHa, ProducaoEsperadaKg) :-
    next_id(campanha(ID,_,_,_,_), ID),
    assertz(campanha(ID, Ano, CulturaId, AreaHa, ProducaoEsperadaKg)),
    format('Campanha registada com ID ~w.~n', [ID]).

listar_campanhas :-
    findall(campanha(Id, Ano, CulturaId, AreaHa, ProducaoEsperada),
            campanha(Id, Ano, CulturaId, AreaHa, ProducaoEsperada),
            Cs),
    sort(Cs, Sorted),
    format('===== CAMPANHAS =====~n'),
    forall(member(X, Sorted), (X = campanha(Id, Ano, CulturaId, AreaHa, ProducaoEsperada),
           (   cultura(CulturaId, CulturaNome, _)
           ->   CulturaName = CulturaNome
           ;   CulturaName = '<??>'
           ),
           format('ID:~w | Ano:~w | Cultura:~w | Area:~w ha | Producao esperada:~w kg~n',
                  [Id, Ano, CulturaName, AreaHa, ProducaoEsperada])
          )).

% ========== F5: Colheitas ==========
registar_colheita(CampanhaId, Data, QuantidadeKg) :-
    next_id(colheita(ID,_,_,_), ID),
    assertz(colheita(ID, CampanhaId, Data, QuantidadeKg)),
    format('Colheita registrada com ID ~w.~n', [ID]).

% ========== F6: Relatório de colheitas ==========
producao_total_campanha(CampanhaId, Total) :-
    findall(Q, colheita(_, CampanhaId, _, Q), Qs),
    sum_list(Qs, Total).

relatorio_colheitas :-
    format('===== RELATÓRIO DE COLHEITAS =====~n'),
    forall(campanha(Id, Ano, CulturaId, _, _),
           (   cultura(CulturaId, CulturaNome, _)
           ->   producao_total_campanha(Id, Total),
                format('Campanha ~w (~w) - ~w:    ~w kg colhidos~n', [Id, Ano, CulturaNome, Total])
           ;   true
           )),
    nl.

% ========== F7: Registo de clientes ==========
registar_cliente(Nome, Username, Password) :-
    registar_cliente(Nome, Username, Password, 0).

registar_cliente(Nome, Username, Password, SaldoInicial) :-
    (   Nome = '' -> format('Erro: nome nao pode ser vazio.~n'), fail
    ;   Username = '' -> format('Erro: username nao pode ser vazio.~n'), fail
    ;   Password = '' -> format('Erro: password nao pode ser vazio.~n'), fail
    ;   SaldoInicial < 0 -> format('Erro: saldo inicial nao pode ser negativo.~n'), fail
    ;   true
    ),
    \+cliente(_, _, Username, _, _),
    next_id(cliente(ID,_,_,_,_), ID),
    assertz(cliente(ID, Nome, Username, Password, SaldoInicial)),
    format('Cliente "~w" registado com ID ~w.~n', [Nome, ID]).

% ========== F8: Autenticacao ==========
% login/2: Autentica cliente e define sessão_atual/1.
%   Sucesso: regista ID na sessão e imprime boas-vindas.
%   Falha: imprime erro, sessão mantém-se inalterada.
login(Username, Password) :-
    (   cliente(Id, Nome, Username, Password, _)
    ->  retractall(sessao_atual(_)),
        assertz(sessao_atual(Id)),
        format('Bem-vindo, ~w! (ID: ~w)~n', [Nome, Id])
    ;   format('Credenciais inválidas.~n')
    ).

% ========== F9: Compra ==========
% Helper to validate positive integer
positive_int(X) :-
    integer(X),
    X > 0.

% comprar/3: ClienteId, ProdutoId, Quantidade
%   Pré-condições (validadas em executar_opcao/1):
%     - ClienteId corresponde ao utilizador logado
%     - ProdutoId existe
%   Validações aqui:
%     1. Quantidade inteira positiva
%     2. Stock suficiente
%     3. Saldo suficiente
comprar(ClienteId, ProdutoId, Quantidade) :-
    positive_int(Quantidade),
    produto(ProdutoId, NomeProduto, Tipo, Preco, Stock, FornecId),
    cliente(ClienteId, NomeCliente, _, _, Saldo),
    Total is Quantidade * Preco,
    Stock >= Quantidade,
    Saldo >= Total,
    !,
    % Update stock
    retract(produto(ProdutoId, NomeProduto, Tipo, Preco, Stock, FornecId)),
    NewStock is Stock - Quantidade,
    assertz(produto(ProdutoId, NomeProduto, Tipo, Preco, NewStock, FornecId)),
    % Update saldo
    retract(cliente(ClienteId, NomeCliente, Username, Password, Saldo)),
    NewSaldo is Saldo - Total,
    assertz(cliente(ClienteId, NomeCliente, Username, Password, NewSaldo)),
    % Create venda and item_venda
    next_id(venda(IDVenda,_,_,_,_), IDVenda),
    get_time(TimeStamp),
    format_time(atom(DataHora), '%Y-%m-%d %H:%M', TimeStamp),
    assertz(venda(IDVenda, ClienteId, NomeCliente, DataHora, Total)),
    assertz(item_venda(IDVenda, ProdutoId, Quantidade, Preco, Total)),
    % Emitir factura
    emitir_factura(IDVenda).

% comprar_varios/2: ClienteId, Lista de itens (item(ProdutoId, Quantidade))
%   Validações iguais a comprar/3 + valida todos os itens antes de processar.
comprar_varios(ClienteId, Items) :-
    % Validação: cliente deve ser o que está logado
    sessao_atual(LogadoId),
    (   LogadoId = nenhum
    ->  format('Erro: nenhum utilizador logado. Faça login primeiro.~n'), fail
    ;   LogadoId = ClienteId
    ->  true
    ;   format('Erro: ID do cliente (~w) não corresponde ao utilizador logado (~w).~n', [ClienteId, LogadoId]), fail
    ),
    % Validar todos os itens: quantidade positiva + produto existe + stock
    frase_for_all(validar_item(ClienteId), Items),
    calcular_total(Items, Total),
    cliente(ClienteId, NomeCliente, Username, Password, Saldo),
    Saldo >= Total,
    !,
    % Processa cada item
    next_id(venda(IDVenda,_,_,_,_), IDVenda),
    get_time(TimeStamp),
    format_time(atom(DataHora), '%Y-%m-%d %H:%M', TimeStamp),
    assertz(venda(IDVenda, ClienteId, NomeCliente, DataHora, Total)),
    forall(member(item(ProdId, Qtd), Items),
           (   produto(ProdId, NomeProd, _, Preco, Stock, FornecId),
               Subtotal is Qtd * Preco,
               retract(produto(ProdId, NomeProd, _, Preco, Stock, FornecId)),
               NewStock is Stock - Qtd,
               assertz(produto(ProdId, NomeProd, _, Preco, NewStock, FornecId)),
               assertz(item_venda(IDVenda, ProdId, Qtd, Preco, Subtotal))
           )),
    % Update saldo
    NewSaldo is Saldo - Total,
    retract(cliente(ClienteId, NomeCliente, Username, Password, Saldo)),
    assertz(cliente(ClienteId, NomeCliente, Username, Password, NewSaldo)),
    % Emitir factura
    emitir_factura(IDVenda).

validar_item(_ClienteId, item(ProdId, Qtd)) :-
    positive_int(Qtd),
    produto(ProdId, _, _, _Preco, Stock, _),
    Stock >= Qtd.

calcular_total([], 0).
calcular_total([item(ProdId, Qtd)|Rest], Total) :-
    produto(ProdId, _, _, Preco, _, _),
    Subtotal is Qtd * Preco,
    calcular_total(Rest, RestTotal),
    Total is Subtotal + RestTotal.

% ========== F10: Factura ==========
emitir_factura(IDVenda) :-
    venda(IDVenda, _IdCliente, NomeCliente, DataHora, Total),
    format('========== FACTURA ==========~n'),
    format('Venda Nº : ~w~n', [IDVenda]),
    format('Data     : ~w~n', [DataHora]),
    format('Cliente  : ~w~n', [NomeCliente]),
    format('-----------------------------~n'),
    forall(item_venda(IDVenda, ProdId, Qtd, PrecoUnitario, Subtotal),
           (   produto(ProdId, NomeProduto, _, _, _, _)
           ->   format('~w~n', [NomeProduto]),
                format('  ~w x ~w MZN = ~w MZN~n', [Qtd, PrecoUnitario, Subtotal])
           ;   true
           )),
    format('-----------------------------~n'),
    format('TOTAL A PAGAR: ~w MZN~n', [Total]),
    format('=============================~n'),
    nl.

% ========== F11: Historico e total de vendas ==========
historico_vendas :-
    findall(venda(Id, NomeCliente, DataHora, Total), venda(Id, _, NomeCliente, DataHora, Total), Vs),
    sort(Vs, Sorted),
    (   Sorted = []
    ->   format('Ainda não há vendas registadas.~n')
    ;   format('===== HISTÓRICO DE VENDAS =====~n'),
        forall(member(venda(Id, NomeCliente, DataHora, Total), Sorted),
               format('Venda ~w | ~w | ~w | ~w MZN~n', [Id, DataHora, NomeCliente, Total])),
        total_vendas(TotalSum),
        format('TOTAL DE VENDAS: ~w MZN~n', [TotalSum])
    ),
    nl.

total_vendas(Total) :-
    findall(T, venda(_,_,_,_,T), Ts),
    sum_list(Ts, Total).

% ========== F12: Menu interactivo ==========
iniciar :-
    format('====================================~n'),
    format(' BEM-VINDO AO SISTEMA AGRÍCOLA~n'),
    format(' Norte de Moçambique - 2025/2026~n'),
    format('====================================~n~n'),
    loop_menu.

loop_menu :-
    menu,
    read_opcao(Opcao),
    (   Opcao = 0
    ->   format('Até breve!~n')
    ;   executar_opcao(Opcao),
        loop_menu
    ).

menu :-
    format('======== SISTEMA AGRÍCOLA ========~n'),
    format('1. Listar fornecedores~n'),
    format('2. Listar produtos~n'),
    format('3. Listar culturas~n'),
    format('4. Listar campanhas~n'),
    format('5. Relatório de colheitas~n'),
    format('6. Registar cliente~n'),
    format('7. Login~n'),
    format('8. Comprar~n'),
    format('9. Histórico de vendas~n'),
    format('0. Sair~n'),
    format('==================================~n'),
    format('Escolha uma opcao(n.): ').

read_opcao(Opcao) :-
    prompt('', ''), % suppress the |: prompt
    catch(read(Opcao), _, (format('Entrada inválida. Termine com ponto (.) e use aspas simples em nomes com espacos, ex.: ''Maria Jose''.~n'), Opcao = -1)),
    (   Opcao < 0 ; Opcao > 9
    ->   format('Opcao invalida.~n'), read_opcao(Opcao)
    ;   true
    ).

executar_opcao(1) :- listar_fornecedores.
executar_opcao(2) :- listar_produtos.
executar_opcao(3) :- listar_culturas.
executar_opcao(4) :- listar_campanhas.
executar_opcao(5) :- relatorio_colheitas.
executar_opcao(6) :-
    format('Nome do cliente: '),
    prompt('', ''),
    catch(read(Nome), _, (format('Entrada inválida.~n'), fail)),
    format('Username: '),
    prompt('', ''),
    catch(read(Username), _, (format('Entrada inválida.~n'), fail)),
    format('Password: '),
    prompt('', ''),
    catch(read(Password), _, (format('Entrada inválida.~n'), fail)),
    format('Saldo inicial (MZN): '),
    prompt('', ''),
    catch(read(Saldo), _, (format('Entrada inválida.~n'), Saldo = -1)),
    (   Saldo < 0
    ->   registar_cliente(Nome, Username, Password)
    ;   registar_cliente(Nome, Username, Password, Saldo)
    ).

executar_opcao(7) :-
    format('Username: '),
    prompt('', ''),
    catch(read(Username), _, (format('Entrada inválida.~n'), fail)),
    format('Password: '),
    prompt('', ''),
    catch(read(Password), _, (format('Entrada inválida.~n'), fail)),
    login(Username, Password).

executar_opcao(8) :-
    format('ID do cliente: '),
    prompt('', ''),
    catch(read(ClienteId), _, (format('Entrada inválida.~n'), fail)),
    % Validação imediata: cliente deve ser o que está logado
    sessao_atual(LogadoId),
    (   LogadoId = nenhum
    ->  format('Erro: nenhum utilizador logado. Faça login primeiro.~n'), fail
    ;   LogadoId = ClienteId
    ->  true
    ;   format('Erro: ID do cliente (~w) não corresponde ao utilizador logado (~w).~n', [ClienteId, LogadoId]), fail
    ),
    format('ID do produto: '),
    prompt('', ''),
    catch(read(ProdutoId), _, (format('Entrada inválida.~n'), fail)),
    % Validação antecipada: produto deve existir
    (   produto(ProdutoId, _, _, _, _, _)
    ->  true
    ;   format('Erro: produto com ID ~w não existe.~n', [ProdutoId]), fail
    ),
    format('Quantidade: '),
    prompt('', ''),
    catch(read(Qtd), _, (format('Entrada inválida.~n'), fail)),
    comprar(ClienteId, ProdutoId, Qtd).

executar_opcao(9) :- historico_vendas.

executar_opcao(_) :- format('Opcao invalida.~n').

% Helper to suppress read prompt
prompt(Prompt, Default) :-
    (   Prompt = '', Default = ''
    ->   true
    ;   format(Prompt), read(Default)
    ).

% Forall helper (since forall/2 may cause choicepoints? but we use forall for side effects only)
frase_for_all(_, []).
frase_for_all(P, [X|Xs]) :-
    call(P, X),
    frase_for_all(P, Xs).