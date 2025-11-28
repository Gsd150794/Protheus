/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |05/04/2021| Chamado 36141. Alterada regra das naturezas.
Lucas Borges  |03/05/2022| Chamado 39985. Tratamento para buscar natureza do Cadastro de TES Inteligente.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT103NTZ
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 29/12/2020
Descrição---------: Este Ponto de Entrada tem por objetivo selecionar a natureza no Documento de Entrada. Ele é chamado em quase
                    todos os pontos do MATA103: ao clicar na aba duplicadas, no browse, ao editar células. Não é chamado quando 
                    a origem é o TOTVS Colaboração.
Parametros--------: ParamIXB[1] -> A -> Natureza
Retorno-----------: cNatureza -> C -> Natureza
===============================================================================================================================
*/
User Function MT103NTZ

Local _cNatOri  := ParamIXB[1]
Local _cNature  := Space(Len(ParamIXB[1]))
Local _nI		:= 0
Local _nEntSai  := 1 //Documento de 1-Entrada / 2-Saida
Local _cTpOper  := ' '//Código da TES Inteligente
Local _cTipoCF  := IIf(cTipo $ 'B/D','C','F') //Tipo Cliente / Fornecedor
Local _cProduto := ""//Codigo do produto
Local _cCampo   := ''//Campo que contem a TES
Local _cTipoCli := ''//Tipo Cliente (F=Cons.Final;L=Prod.Rural;R=Revendedor;S=Solidario;X=Exportacao/Importacao)
Local _cEstOrig := ''//Estado de Origem do documento
Local _cOrigem  := ''//

If !IsInCallStack("U_MGLT009") .And. (;//Não executa no fechamento do leite
    !(FWIsInCallStack("NFEEMISSAO") .Or. FWIsInCallStack("EDITCELL") .Or. FWIsInCallStack("NFECABOK") .Or. FWIsInCallStack("NFEVLDREF")) .Or.;//não executar em qualquer dessas situações: click no browse - Edita/clica célula - valida cabeçalho - Digita natureza
    (!FWIsInCallStack("NFECABOK") .And. FWIsInCallStack("SAFEEVAL"))) //Executa no clique do Salvar, na segunda, de três chamadas. Na primeira e última o NFECABOK está na pilha.

    If cTipo == "D"
        _cNature := SuperGetMV("IT_DEVNATU",.F.,"410001")
    //Não achei forma melhor de evitar que passe nesse trecho ao informar o vencimento.
    //Ele usa o mesmo aCols para os dados da duplicata
    ElseIf Len(aHeader) > 100 .And. Empty(_cNature)
        For _nI := 1 To Len( aCols )
            _cProduto := AllTrim(aCols[_nI][aScan(aHeader,{|x| Upper(AllTrim(x[2])) == 'D1_COD'})])
            _cTpOper  := AllTrim(aCols[_nI][aScan(aHeader,{|x| Upper(AllTrim(x[2])) == 'D1_OPER'})])
            
            If !Empty(_cTpOper)
                _cNature:= U_MaNatInt(_nEntSai,_cTpOper,cA100For,cLoja,_cTipoCF,_cProduto,_cCampo,_cTipoCli,_cEstOrig,_cOrigem)
            EndIf
            If !Empty(_cNature)
                Exit
            EndIf
        Next _nI
    EndIf
    //Só pergunto se deseja manter a natureza informada manualmente se For na confirmação do documento
    If !l103Auto .And. !Empty(_cNature) .And. !Empty(_cNatOri) .And. AllTrim(_cNatOri) <> AllTrim(_cNature);
        .And. FWIsInCallStack("SAFEEVAL") .And.;
        MsgYesNo("A natureza identificada no cadastro de TES Inteligente '"+AllTrim(_cNature)+"' está diferente da informada no documento '"+AllTrim(_cNatOri)+"'. "+;
                    "Deseja manter a Natureza informada no documento?","MT103NTZ01")
       _cNature := _cNatOri
    EndIf
EndIf
If Empty(_cNature)// Preenche com o conteúdo recebido/digitado no campo quando nenhuma regra preenche o conteúdo. Usado para manter o conteúdo sem alteração
    _cNature := _cNatOri
EndIf

Return (_cNature)
