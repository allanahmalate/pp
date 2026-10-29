:- encoding(utf8).
:- ensure_loaded('dados.pl').

% ============================================================================
% AGRICOLA.PL - Sistema de Gestão Agrícola para Norte de Moçambique
% ============================================================================
% Funcionalidades:
%   F1  Fornecedores        - CRUD
%   F2  Produtos            - Catálogo com stock
%   F3  Culturas            - Registo de culturas/variedades
%   F4  Campanhas           - Campanhas agrícolas por cultura
%   F5  Colheitas           - Registo de colheitas por campanha
%   F6  Relatório Colheitas - Produção total por campanha
%   F7  Clientes            - Registo com validações
%   F8  Autenticação        - Login + sessão única
%   F9  Compras             - Simples e múltiplas (transação atómica)
%   F10 Factura             - Emissão formatada
%   F11 Histórico Vendas    - Listagem + totais
%   F12 Menu Interactivo    - Loop principal terminal
% ============================================================================

% ----------------------------------------------------------------------------
% PREDICADOS DINÂMICOS
% ----------------------------------------------------------------------------
:- dynamic sessao_atual/1.
sessao_atual(nenhum).

% ----------------------------------------------------------------------------
% UTILITÁRIOS: IDs sequenciais
% ----------------------------------------------------------------------------
% max_id(+Func/Arit, -Max): maior ID usado (0 se nenhum)
% next_id(+Func/Arit, -Next): Max + 1
max_id(Func, Max) :-
    findall(ID, (Func, arg(1, Func, ID)), IDs),
    (IDs = [] -> Max = 0 ; max_list(IDs, Max)).

next_id(Func, Next) :- max_id(Func, Max), Next is Max + 1.

% ============================================================================
% F1: FORNECEDORES
% ============================================================================
% fornecedor(ID, Nome, Tipo, Contacto)
registar_fornecedor(Nome, Tipo, Contacto) :-
    next_id(fornecedor(ID,_,_,_), ID),
    assertz(fornecedor(ID, Nome, Tipo, Contacto)),
    format('Fornecedor "~w" registado com ID ~w.~n', [Nome, ID]).

listar_fornecedores :-
    findall(fornecedor(Id, Nome, Tipo, Contacto), fornecedor(Id, Nome, Tipo, Contacto), Ls),
    sort(Ls, Sorted),
    format('===== FORNECEDORES =====~n'),
    forall(member(fornecedor(Id, Nome, Tipo, Contacto), Sorted),
           format('ID:~w | Nome:~w | Tipo:~w | Contato:~w~n', [Id, Nome, Tipo, Contacto])).

% ============================================================================
% F2: PRODUTOS
% ============================================================================
% produto(ID, Nome, Tipo, Preco, Stock, FornecedorId)
registar_produto(Nome, Tipo, Preco, FornecedorId) :-
    next_id(produto(ID,_,_,_,_,_), ID),
    assertz(produto(ID, Nome, Tipo, Preco, 0, FornecedorId)),
    format('Produto "~w" registado com ID ~w.~n', [Nome, ID]).

listar_produtos :-
    findall(produto(Id, Nome, Tipo, Preco, Stock, FornId), produto(Id, Nome, Tipo, Preco, Stock, FornId), Ls),
    sort(Ls, Sorted),
    format('===== CATALOGO DE PRODUTOS =====~n'),
    forall(member(produto(Id, Nome, Tipo, Preco, Stock, FornId), Sorted),
           print_produto(Id, Nome, Tipo, Preco, Stock, FornId)).

print_produto(Id, Nome, Tipo, Preco, Stock, FornId) :-
    atom_concat(Preco, ' MZN', PrecoMzn),
    (fornecedor(FornId, ForNome, _, _) -> FornecedorName = ForNome ; FornecedorName = '<??>'),
    format('ID:~w | ~-24w | ~-12w | ~-11w | Stock:~w | Fornecedor:~w~n',
           [Id, Nome, Tipo, PrecoMzn, Stock, FornecedorName]).

% ============================================================================
% F3: CULTURAS
% ============================================================================
% cultura(ID, Nome, Variedade)
registar_cultura(Nome, Variedade) :-
    next_id(cultura(ID,_,_), ID),
    assertz(cultura(ID, Nome, Variedade)),
    format('Cultura "~w" registada com ID ~w.~n', [Nome, ID]).

listar_culturas :-
    findall(cultura(Id, Nome, Var), cultura(Id, Nome, Var), Ls),
    sort(Ls, Sorted),
    format('===== CULTURAS =====~n'),
    forall(member(cultura(Id, Nome, Var), Sorted),
           format('ID:~w | Nome:~w | Variedade:~w~n', [Id, Nome, Var])).

% ============================================================================
% F4: CAMPANHAS
% ============================================================================
% campanha(ID, Ano, CulturaId, AreaHa, ProducaoEsperadaKg)
registar_campanha(Ano, CulturaId, AreaHa, ProducaoEsperadaKg) :-
    next_id(campanha(ID,_,_,_,_), ID),
    assertz(campanha(ID, Ano, CulturaId, AreaHa, ProducaoEsperadaKg)),
    format('Campanha registada com ID ~w.~n', [ID]).

listar_campanhas :-
    findall(campanha(Id, Ano, CulId, Area, Prod), campanha(Id, Ano, CulId, Area, Prod), Ls),
    sort(Ls, Sorted),
    format('===== CAMPANHAS =====~n'),
    forall(member(campanha(Id, Ano, CulId, Area, Prod), Sorted),
           (cultura(CulId, CulNome, _) -> CulNome1 = CulNome ; CulNome1 = '<??>'),
           format('ID:~w | Ano:~w | Cultura:~w | Area:~w ha | Producao esperada:~w kg~n',
                  [Id, Ano, CulNome1, Area, Prod])).
                  
% ============================================================================
% F5: COLHEITAS
% ============================================================================
% colheita(ID, CampanhaId, Data, QuantidadeKg)
registar_colheita(CampanhaId, Data, QuantidadeKg) :-
    next_id(colheita(ID,_,_,_), ID),
    assertz(colheita(ID, CampanhaId, Data, QuantidadeKg)),
    format('Colheita registrada com ID ~w.~n', [ID]).

% ============================================================================
% F6: RELATÓRIO DE COLHEITAS
% ============================================================================
producao_total_campanha(CampanhaId, Total) :-
    findall(Q, colheita(_, CampanhaId, _, Q), Qs),
    sum_list(Qs, Total).

relatorio_colheitas :-
    format('===== RELATÓRIO DE COLHEITAS =====~n'),
    forall(campanha(Id, Ano, CulId, _, _),
           (cultura(CulId, CulNome, _) ->
               producao_total_campanha(Id, Total),
               format('Campanha ~w (~w) - ~w:    ~w kg colhidos~n', [Id, Ano, CulNome, Total])
            ; true)),
    nl.

% ============================================================================
% F7: CLIENTES
% ============================================================================
% cliente(ID, Nome, Username, Password, Saldo)
registar_cliente(Nome, Username, Password) :- registar_cliente(Nome, Username, Password, 0).

registar_cliente(Nome, Username, Password, SaldoInicial) :-
    (Nome = ''       -> format('Erro: nome nao pode ser vazio.~n'), fail
    ; Username = ''  -> format('Erro: username nao pode ser vazio.~n'), fail
    ; Password = ''  -> format('Erro: password nao pode ser vazio.~n'), fail
    ; SaldoInicial < 0 -> format('Erro: saldo inicial nao pode ser negativo.~n'), fail
    ; true),
    \+ cliente(_, _, Username, _, _),
    next_id(cliente(ID,_,_,_,_), ID),
    assertz(cliente(ID, Nome, Username, Password, SaldoInicial)),
    format('Cliente "~w" registado com ID ~w.~n', [Nome, ID]).

% ============================================================================
% F8: AUTENTICAÇÃO E SESSÃO
% ============================================================================
% login/2: verifica credenciais e cria sessão única
login(Username, Password) :-
    (cliente(Id, Nome, Username, Password, _) ->
        retractall(sessao_atual(_)),
        assertz(sessao_atual(Id)),
        format('Bem-vindo, ~w! (ID: ~w)~n', [Nome, Id])
    ; format('Credenciais inválidas.~n')
    ).

% ============================================================================
% F9: COMPRAS
% ============================================================================
positive_int(X) :- integer(X), X > 0.

% comprar/3: compra única - validações + efeitos atómicos (corte !)
comprar(ClienteId, ProdutoId, Quantidade) :-
    positive_int(Quantidade),
    produto(ProdutoId, NomeProd, Tipo, Preco, Stock, FornId),
    cliente(ClienteId, NomeCli, _, _, Saldo),
    Total is Quantidade * Preco,
    Stock >= Quantidade,
    Saldo >= Total,
    !,
    % stock
    retract(produto(ProdutoId, NomeProd, Tipo, Preco, Stock, FornId)),
    NewStock is Stock - Quantidade,
    assertz(produto(ProdutoId, NomeProd, Tipo, Preco, NewStock, FornId)),
    % saldo
    retract(cliente(ClienteId, NomeCli, User, Pass, Saldo)),
    NewSaldo is Saldo - Total,
    assertz(cliente(ClienteId, NomeCli, User, Pass, NewSaldo)),
    % venda + item
    next_id(venda(IDV,_,_,_,_), IDV),
    get_time(Ts), format_time(atom(DH), '%Y-%m-%d %H:%M', Ts),
    assertz(venda(IDV, ClienteId, NomeCli, DH, Total)),
    assertz(item_venda(IDV, ProdutoId, Quantidade, Preco, Total)),
    emitir_factura(IDV).

% comprar_varios/2: múltiplos itens - valida tudo antes de executar (all-or-nothing)
comprar_varios(ClienteId, Items) :-
    sessao_atual(LogadoId),
    (LogadoId = nenhum          -> format('Erro: nenhum utilizador logado.~n'), fail
    ; LogadoId = ClienteId      -> true
    ; format('Erro: ID cliente (~w) != logado (~w).~n', [ClienteId, LogadoId]), fail),
    frase_for_all(validar_item(ClienteId), Items),
    calcular_total(Items, Total),
    cliente(ClienteId, NomeCli, User, Pass, Saldo),
    Saldo >= Total,
    !,
    next_id(venda(IDV,_,_,_,_), IDV),
    get_time(Ts), format_time(atom(DH), '%Y-%m-%d %H:%M', Ts),
    assertz(venda(IDV, ClienteId, NomeCli, DH, Total)),
    forall(member(item(Pid, Qtd), Items),
           (produto(Pid, Nom, _, Preco, Stock, Fid),
            Sub is Qtd * Preco,
            retract(produto(Pid, Nom, _, Preco, Stock, Fid)),
            assertz(produto(Pid, Nom, _, Preco, Stock-Qtd, Fid)),
            assertz(item_venda(IDV, Pid, Qtd, Preco, Sub)))),
    retract(cliente(ClienteId, NomeCli, User, Pass, Saldo)),
    assertz(cliente(ClienteId, NomeCli, User, Pass, Saldo-Total)),
    emitir_factura(IDV).

validar_item(_Cli, item(Pid, Qtd)) :-
    positive_int(Qtd),
    produto(Pid, _, _, _Preco, Stock, _),
    Stock >= Qtd.

calcular_total([], 0).
calcular_total([item(Pid, Qtd)|Rest], Total) :-
    produto(Pid, _, _, Preco, _, _),
    Sub is Qtd * Preco,
    calcular_total(Rest, RTotal),
    Total is Sub + RTotal.

% ============================================================================
% F10: FACTURA
% ============================================================================
emitir_factura(IDV) :-
    venda(IDV, _, NomeCli, DH, Total),
    format('========== FACTURA ==========~n'),
    format('Venda Nº : ~w~n', [IDV]),
    format('Data     : ~w~n', [DH]),
    format('Cliente  : ~w~n', [NomeCli]),
    format('-----------------------------~n'),
    forall(item_venda(IDV, Pid, Qtd, PU, Sub),
           (produto(Pid, Nom, _, _, _, _) ->
               format('~w~n', [Nom]),
               format('  ~w x ~w MZN = ~w MZN~n', [Qtd, PU, Sub])
            ; true)),
    format('-----------------------------~n'),
    format('TOTAL A PAGAR: ~w MZN~n', [Total]),
    format('=============================~n'),
    nl.

% ============================================================================
% F11: HISTÓRICO DE VENDAS
% ============================================================================
historico_vendas :-
    findall(venda(Id, NomeCli, DH, Total), venda(Id, _, NomeCli, DH, Total), Ls),
    sort(Ls, Sorted),
    (Sorted = [] ->
        format('Ainda não há vendas registadas.~n')
    ;   format('===== HISTÓRICO DE VENDAS =====~n'),
        forall(member(venda(Id, NomeCli, DH, Total), Sorted),
               format('Venda ~w | ~w | ~w | ~w MZN~n', [Id, DH, NomeCli, Total])),
        total_vendas(Sum),
        format('TOTAL DE VENDAS: ~w MZN~n', [Sum])
    ),
    nl.

total_vendas(Total) :- findall(T, venda(_,_,_,_,T), Ts), sum_list(Ts, Total).

% ============================================================================
% F12: MENU INTERACTIVO
% ============================================================================
:- discontiguous executar_opcao/1.

iniciar :-
    format('====================================~n'),
    format(' BEM-VINDO AO SISTEMA AGRÍCOLA~n'),
    format(' Norte de Moçambique - 2025/2026~n'),
    format('====================================~n~n'),
    loop_menu.

loop_menu :-
    menu,
    read_opcao(Opcao),
    (Opcao = 0 -> format('Até breve!~n')
    ; executar_opcao(Opcao), loop_menu).

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
    format('==================================~n').

% read_opcao/1: usa prompt/2 BUILTIN do SWI-Prolog
% prompt(Old, New) guarda actual e define novo para próximo read/1
% prompt(_, Old) restaura
read_opcao(Opcao) :-
    prompt(Old, 'Escolha uma opcao(n.): '),
    catch(read(Opcao), _, (format('Entrada inválida. Termine com ponto (.)~n'), Opcao = -1)),
    prompt(_, Old),
    (Opcao < 0 ; Opcao > 9 -> format('Opcao invalida.~n'), read_opcao(Opcao) ; true).

% --- Dispatchers ---
executar_opcao(1) :- listar_fornecedores.
executar_opcao(2) :- listar_produtos.
executar_opcao(3) :- listar_culturas.
executar_opcao(4) :- listar_campanhas.
executar_opcao(5) :- relatorio_colheitas.

% Registo cliente
executar_opcao(6) :-
    prompt(O1, 'Nome do cliente: '),
    catch(read(Nome), _, (prompt(_, O1), format('Entrada inválida.~n'), fail)),
    prompt(O2, 'Username: '),
    catch(read(User), _, (prompt(_, O2), format('Entrada inválida.~n'), fail)),
    prompt(O3, 'Password: '),
    catch(read(Pass), _, (prompt(_, O3), format('Entrada inválida.~n'), fail)),
    prompt(O4, 'Saldo inicial (MZN): '),
    catch(read(Saldo), _, (prompt(_, O4), format('Entrada inválida.~n'), Saldo = -1)),
    (Saldo < 0 -> registar_cliente(Nome, User, Pass) ; registar_cliente(Nome, User, Pass, Saldo)).

% Login
executar_opcao(7) :-
    prompt(O1, 'Username: '),
    catch(read(User), _, (prompt(_, O1), format('Entrada inválida.~n'), fail)),
    prompt(O2, 'Password: '),
    catch(read(Pass), _, (prompt(_, O2), format('Entrada inválida.~n'), fail)),
    login(User, Pass).

% Compra
executar_opcao(8) :-
    format('ID do cliente: '), flush_output,
    catch(read(CliId), _, (format('Entrada inválida.~n'), fail)),
    (sessao_atual(LogId), LogId \= nenhum, LogId = CliId ->
        prompt(O1, 'ID do produto: '),
        catch(read(ProdId), _, (prompt(_, O1), format('Entrada inválida.~n'), fail)),
        (produto(ProdId, _, _, _, Stock, _) -> true
        ; format('Erro: produto ~w inexistente.~n', [ProdId]), fail),
        ler_quantidade_valida(ProdId, Stock, Qtd),
        (comprar(CliId, ProdId, Qtd) -> true ; format('Erro: compra falhou (saldo?).~n'))
    ; sessao_atual(LogId),
      (LogId = nenhum -> format('Erro: faça login primeiro.~n')
       ; format('Erro: ID cliente (~w) != logado (~w).~n', [CliId, LogId]))).

ler_quantidade_valida(ProdId, Stock, Qtd) :-
    prompt(Old, 'Quantidade (stock: ~w): '),
    catch(read(Raw), _, (prompt(_, Old), format('Entrada inválida.~n'), ler_quantidade_valida(ProdId, Stock, Qtd))),
    (number(Raw), Raw > 0, Raw =< Stock -> Qtd is round(Raw)
    ; format('Erro: quantidade inválida, stock ~w.~n', [Stock]), ler_quantidade_valida(ProdId, Stock, Qtd)).

executar_opcao(9) :- historico_vendas.
executar_opcao(_) :- format('Opcao invalida.~n').

% ----------------------------------------------------------------------------
% HELPER: forall determinístico para listas
% ----------------------------------------------------------------------------
frase_for_all(_, []).
frase_for_all(P, [X|Xs]) :- call(P, X), frase_for_all(P, Xs).