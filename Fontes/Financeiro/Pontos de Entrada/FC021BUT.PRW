/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
 Lucas Borges |09/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: FC021BUT
Autor-------------: Josué Danich Prestes
Data da Criacao---: 07/06/2019
Descrição---------: PE Inclusao de botao na tela de consulta de fluxo de caixa - Chamado 29347
					Ponto de entrada que permite ao usuário criar novos botões na EnchoiceBar da tela de detalhamento (Fluxo 
					Analitico) do fluxo de caixa.
Parametros--------: Nenhum
Retorno-----------: uRet -> A -> array com os dados da opção
===============================================================================================================================
*/
User Function FC021BUT()

Local _abut := {{"Exporta",	{|| FWMsgRun(,{|| U_FC021EXP()},"Aguarde...","Gerando arquivo...") }, "Exporta Excel"}}

Return _abut

/*
===============================================================================================================================
Programa----------: FC021EXP
Autor-------------: Josué Danich Prestes
Data da Criacao---: 07/06/2019
Descrição---------: Exportacao de fluxo de caixa para excel
Parametros--------: Nenhum
Retorno-----------: Nenhum.
===============================================================================================================================
*/
User Function FC021EXP()

Local oExcel	:= FWMSEXCEL():New()
Local cArquivo	:= GetTempPath()+'fluxo.xml'
Local _nt		:= 0
If file(cArquivo)

    _nap := ferase(cArquivo)
    
    If _nap < 0 

        U_ITMsg(cArquivo + " não pode ser atualizado!","Atenção",,1)
        Return

    EndIf

EndIf

_atables := {}

aAdd(_atables,"A Pagar")
aAdd(_atables,"A Receber")
aAdd(_atables,"Pedido de Compra")
aAdd(_atables,"Pedido de Venda")
aAdd(_atables,"Comissões")
aAdd(_atables,"Emprestimos")
aAdd(_atables,"Aplicações")
aAdd(_atables,"Cheques pendentes")
aAdd(_atables,"Doctos. de Transporte")
aAdd(_atables,"Solicitações de Fundo")
aAdd(_atables,"Ped. Compra de Máquinas")
aAdd(_atables,"Ped. Venda de Máquinas")

For _nt := 1 to Len(_atables)

    If _atables[_nt] == "A Pagar"

        _caliaspc := "cArqAnaP"

        If Select(_caliaspc)  = 0

            Loop

        EndIf

        oExcel:AddworkSheet(_atables[_nt])
        oExcel:AddTable (_atables[_nt],_atables[_nt])

        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Filial",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Prefixo",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Numero",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Parc",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Tipo",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Fornecedor",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Nome",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Loja",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Valor",3,2)

        _npos := (_caliaspc)->(Recno())

        (_caliaspc)->(DBGoTop())

        While !((_caliaspc)->(Eof()))

             oExcel:AddRow(_atables[_nt],_atables[_nt],{(_caliaspc)->FILIAL,;
                                                        (_caliaspc)->PREFIXO,;
                                                        (_caliaspc)->NUM,;
                                                        (_caliaspc)->PARCELA,;
                                                        (_caliaspc)->TIPO,;
                                                        (_caliaspc)->CLIFOR,;
                                                        (_caliaspc)->NOMCLIFOR,;
                                                        (_caliaspc)->LOJA,;
                                                        (_caliaspc)->SALDO})

            (_caliaspc)->(DBSkip())

        EndDo

        (_caliaspc)->(DBGoTo(_npos))

    EndIf


    If _atables[_nt] == "A Receber"

         _caliaspc := "cArqAnaR"

         If Select(_caliaspc)  = 0

            Loop

        EndIf


        oExcel:AddworkSheet(_atables[_nt])
        oExcel:AddTable (_atables[_nt],_atables[_nt])

        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Filial",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Prefixo",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Numero",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Parc",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Tipo",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Cliente",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Nome",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Loja",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Valor",3,2)
     
        _npos := (_caliaspc)->(Recno())

        (_caliaspc)->(DBGoTop())

        While !((_caliaspc)->(Eof()))

             oExcel:AddRow(_atables[_nt],_atables[_nt],{(_caliaspc)->FILIAL,;
                                                        (_caliaspc)->PREFIXO,;
                                                        (_caliaspc)->NUM,;
                                                        (_caliaspc)->PARCELA,;
                                                        (_caliaspc)->TIPO,;
                                                        (_caliaspc)->CLIFOR,;
                                                        (_caliaspc)->NOMCLIFOR,;
                                                        (_caliaspc)->LOJA,;
                                                        (_caliaspc)->SALDO})

            (_caliaspc)->(DBSkip())

        EndDo

        (_caliaspc)->(DBGoTo(_npos))

    EndIf
   
    If _atables[_nt] == "Pedido de Compra"

        _caliaspc := "cArqAnaPc"

        If Select(_caliaspc)  = 0

            Loop

        EndIf


        oExcel:AddworkSheet(_atables[_nt])
        oExcel:AddTable (_atables[_nt],_atables[_nt])

        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Numero",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Emissao",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Fornecedor",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Nome",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Tipo",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Item",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Produto",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Valor",3,2)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Valor do Adiantamento",3,2)

        _npos := (_caliaspc)->(Recno())

        (_caliaspc)->(DBGoTop())

        While !((_caliaspc)->(Eof()))

             oExcel:AddRow(_atables[_nt],_atables[_nt],{(_caliaspc)->NUMERO,;
                                                        DToC((_caliaspc)->EMISSAO),;
                                                        (_caliaspc)->CLIFOR,;
                                                        (_caliaspc)->NOMCLIFOR,;
                                                        (_caliaspc)->TIPO,;
                                                        (_caliaspc)->ITEM,;
                                                        (_caliaspc)->PRODUTO,;
                                                        (_caliaspc)->SALDO,;
                                                        (_caliaspc)->VALPAGANT})

            (_caliaspc)->(DBSkip())

        EndDo

        (_caliaspc)->(DBGoTo(_npos))

    EndIf

    If _atables[_nt] == "Pedido de Venda"

        _caliaspc := "cArqAnaPv"

        If Select(_caliaspc)  = 0

            Loop

        EndIf

        oExcel:AddworkSheet(_atables[_nt])
        oExcel:AddTable (_atables[_nt],_atables[_nt])

        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Numero",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Tipo",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Emissao",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Cliente",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Nome",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Loja Cliente",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Loja Entrega",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Valor",3,2)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Valor do Adiantamento",3,2)

        _npos := (_caliaspc)->(Recno())

        (_caliaspc)->(DBGoTop())

        While !((_caliaspc)->(Eof()))

             oExcel:AddRow(_atables[_nt],_atables[_nt],{(_caliaspc)->NUMERO,;
                                                        (_caliaspc)->TIPO,;
                                                        DToC((_caliaspc)->EMISSAO),;
                                                        (_caliaspc)->CLIFOR,;
                                                        (_caliaspc)->NOMCLIFOR,;
                                                        (_caliaspc)->LOJACLI,;
                                                        (_caliaspc)->LOJAENT,;
                                                        (_caliaspc)->SALDO,;
                                                        (_caliaspc)->VALRECANT})

            (_caliaspc)->(DBSkip())

        EndDo

        (_caliaspc)->(DBGoTo(_npos))

    EndIf

    If _atables[_nt] == "Comissões"

        _caliaspc := "cArqAnaCo"

        If Select(_caliaspc)  = 0

            Loop

        EndIf
        
        oExcel:AddworkSheet(_atables[_nt])
        oExcel:AddTable (_atables[_nt],_atables[_nt])

        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Filial",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Prefixo",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Numero",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Parcela",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Vendedor",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Nome",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Valor",3,2)
  
        _npos := (_caliaspc)->(Recno())

        (_caliaspc)->(DBGoTop())

        While !((_caliaspc)->(Eof()))

             oExcel:AddRow(_atables[_nt],_atables[_nt],{(_caliaspc)->FILIAL,;
                                                        (_caliaspc)->PREFIXO,;
                                                        (_caliaspc)->NUMERO,;
                                                        (_caliaspc)->PARCELA,;
                                                        (_caliaspc)->VEND,;
                                                        (_caliaspc)->NOMEVEND,;
                                                        (_caliaspc)->VALOR})

            (_caliaspc)->(DBSkip())

        EndDo

        (_caliaspc)->(DBGoTo(_npos))

    EndIf

    If _atables[_nt] == "Emprestimos"

        _caliaspc := "cArqAnaEmp"

        If Select(_caliaspc)  = 0

            Loop

        EndIf
        
        oExcel:AddworkSheet(_atables[_nt])
        oExcel:AddTable (_atables[_nt],_atables[_nt])

        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Numero",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Banco",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Agencia",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Conta",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Emissao",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Valor",3,2)
  
        _npos := (_caliaspc)->(Recno())

        (_caliaspc)->(DBGoTop())

        While !((_caliaspc)->(Eof()))

             oExcel:AddRow(_atables[_nt],_atables[_nt],{(_caliaspc)->NUMERO,;
                                                        (_caliaspc)->BANCO,;
                                                        (_caliaspc)->AGENCIA,;
                                                        (_caliaspc)->CONTA,;
                                                        DToC((_caliaspc)->AGENCIA),;
                                                        (_caliaspc)->VALOR})

            (_caliaspc)->(DBSkip())

        EndDo

        (_caliaspc)->(DBGoTo(_npos))


    EndIf

    If _atables[_nt] == "Aplicações"

        _caliaspc := "cArqAnaApl"

        If Select(_caliaspc)  = 0

            Loop

        EndIf
        
        oExcel:AddworkSheet(_atables[_nt])
        oExcel:AddTable (_atables[_nt],_atables[_nt])

        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Numero",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Banco",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Agencia",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Conta",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Emissao",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Valor",3,2)
  
        _npos := (_caliaspc)->(Recno())

        (_caliaspc)->(DBGoTop())

        While !((_caliaspc)->(Eof()))

             oExcel:AddRow(_atables[_nt],_atables[_nt],{(_caliaspc)->NUMERO,;
                                                        (_caliaspc)->BANCO,;
                                                        (_caliaspc)->AGENCIA,;
                                                        (_caliaspc)->CONTA,;
                                                        DToC((_caliaspc)->AGENCIA),;
                                                        (_caliaspc)->VALOR})

            (_caliaspc)->(DBSkip())

        EndDo

        (_caliaspc)->(DBGoTo(_npos))

    EndIf

    If _atables[_nt] == "Cheques pendentes"

        _caliaspc := "cArqAnaChq"

        If Select(_caliaspc)  = 0

            Loop

        EndIf
        
        oExcel:AddworkSheet(_atables[_nt])
        oExcel:AddTable (_atables[_nt],_atables[_nt])

        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Numero",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Banco",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Agencia",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Conta",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Valor",3,2)
  
        _npos := (_caliaspc)->(Recno())

        (_caliaspc)->(DBGoTop())

        While !((_caliaspc)->(Eof()))

             oExcel:AddRow(_atables[_nt],_atables[_nt],{(_caliaspc)->NUMERO,;
                                                        (_caliaspc)->BANCO,;
                                                        (_caliaspc)->AGENCIA,;
                                                        (_caliaspc)->CONTA,;
                                                        (_caliaspc)->SALDO})

            (_caliaspc)->(DBSkip())

        EndDo

        (_caliaspc)->(DBGoTo(_npos))


    EndIf

    If _atables[_nt] == "Doctos. de Transporte"

        _caliaspc := "cArqAnaCo"

        If Select(_caliaspc)  = 0

            Loop

        EndIf
        
        oExcel:AddworkSheet(_atables[_nt])
        oExcel:AddTable (_atables[_nt],_atables[_nt])

        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Filial Pag",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Filial Orig",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Documento",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Serie",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Emissao",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Valor",3,2)
  
        _npos := (_caliaspc)->(Recno())

        (_caliaspc)->(DBGoTop())

        While !((_caliaspc)->(Eof()))

             oExcel:AddRow(_atables[_nt],_atables[_nt],{(_caliaspc)->FILDEB,;
                                                        (_caliaspc)->FILDOC,;
                                                        (_caliaspc)->DOC,;
                                                        (_caliaspc)->SERIE,;
                                                        DToC((_caliaspc)->EMISSAO),;
                                                        (_caliaspc)->VALOR})

            (_caliaspc)->(DBSkip())

        EndDo

        (_caliaspc)->(DBGoTo(_npos))


    EndIf

    If _atables[_nt] == "Solicitações de Fundo"

        _caliaspc := "cArqAnaCo"

        If Select(_caliaspc)  = 0

            Loop

        EndIf
        
        oExcel:AddworkSheet(_atables[_nt])
        oExcel:AddTable (_atables[_nt],_atables[_nt])
  
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Filial",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Funcao",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Fornecedor",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Loja",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Data Pr",2,1)
        oExcel:AddColumn(_atables[_nt],_atables[_nt],"Valor",3,2)
  
        _npos := (_caliaspc)->(Recno())

        (_caliaspc)->(DBGoTop())

        While !((_caliaspc)->(Eof()))

             oExcel:AddRow(_atables[_nt],_atables[_nt],{(_caliaspc)->FILIAL,;
                                                        (_caliaspc)->SOLFUN,;
                                                        (_caliaspc)->FORNEC,;
                                                        (_caliaspc)->LOJA,;
                                                        DToC((_caliaspc)->DATAPR),;
                                                        (_caliaspc)->VALOR})

            (_caliaspc)->(DBSkip())

        EndDo

        (_caliaspc)->(DBGoTo(_npos))


    EndIf

    
Next

oExcel:Activate()
oExcel:GetXMLFile(carquivo)

//Abrindo o excel e abrindo o arquivo xml
oExcel := MsExcel():New()             //Abre uma nova conexão com Excel
oExcel:WorkBooks:Open(cArquivo)     //Abre uma planilha
oExcel:SetVisible(.T.)                 //Visualiza a planilha
oExcel:Destroy()                        //Encerra o processo do gerenciador de tarefas

Return
