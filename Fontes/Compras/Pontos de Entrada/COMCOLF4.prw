/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |29/12/2020| Chamado 34986. Incluídos os tratamentos para todas as filiais.
Lucas Borges  |03/05/2022| Chamado 39985. Ajuste na gravação do Tipo de Operação.
Lucas Borges  |22/05/2022| Chamado 40178. Ajuste na gravação do Tipo de Operação.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: COMCOLF4
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 03/06/2020
Descrição-------: Permite alterar e validar a TES utilizada no monitor do totvs colaboração
				 LOCALIZAÇÃO: No monitor Totvs Colaboração
Parametros--------: ParamIXB[01] -> C -> Fornecedor
                    ParamIXB[02] -> C -> Loja
                    ParamIXB[03] -> C -> Produto
                    ParamIXB[04] -> C -> TES
Retorno---------: cTes -> C -> TES
===============================================================================================================================
*/
User Function COMCOLF4

Local _cTes     := ParamIXB[4]
Local _nEntSai  := 1 //Documento de 1-Entrada / 2-Saida
Local _cTpOper  := ''//Código da TES Inteligente
Local _cClieFor := ParamIXB[1]//Codigo do Cliente ou Fornecedor
Local _cLoja    := ParamIXB[2]//Codigo da Loja do Cli/Forn 
Local _cTipoCF  := IIf(SDS->DS_TIPO $ 'B/D','C','F') //Tipo Cliente / Fornecedor
Local _cProduto := ParamIXB[3]//Codigo do produto
Local _cCampo   := ''//Campo que contem a TES
Local _cTipoCli := ''//Tipo Cliente (F=Cons.Final;L=Prod.Rural;R=Revendedor;S=Solidario;X=Exportacao/Importacao)
Local _cEstOrig := ''//Estado de Origem do documento
Local _cOrigem  := ''//

//CT-e não tem CFOP, logo, a regra deve ser explicida.
If AllTrim(SDS->DS_ESPECI) == 'CTE' //Operações com CT-e
    If SDS->DS_UFORITR == SDS->DS_UFDESTR//SDS->DS_EST == SM0->M0_ESTENT
        _cTpOper := '10'
    Else
        _cTpOper := '11'
    EndIf
EndIf
//Demais documentos consigo buscar o tipo de operação pelo CFOP
If Empty(_cTpOper)
    _cTpOper := ColConDHJ(SDT->DT_CODCFOP)
EndIf
//O MaTesInt é executado logo antes de chamar o PE, porém ele nem sempre terá o Tipo de Operação para fazera busca correta.
//Infelizmente é necessário chamar a função de novo, mesmo prejudicando a performance. No COMXCOL ela só é executada se não localizar
//uma TES, seja no pedido, na devolução ou na SDT. Já aqui eu sempre executo ela e ignoro o conteúdo anterior, conforme definido pela
//Luciane e Samir. O que prevalece é a TES inteligente e não o que o usuário informar.
If !Empty(_cTpOper)
    _cTes:= MaTesInt(_nEntSai,_cTpOper,_cClieFor,_cLoja,_cTipoCF,_cProduto,_cCampo,_cTipoCli,_cEstOrig,_cOrigem)
EndIf

Return _cTes
