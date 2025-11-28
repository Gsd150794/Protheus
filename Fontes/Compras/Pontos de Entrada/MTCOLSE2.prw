/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  | 23/07/2021 | Implementado tratamento para o vencimento das devoluções. Chamado 37255
Lucas Borges  | 02/08/2021 | Corrigida a validação para o PE não ser chamado indevidamente. Chamado 37339
Lucas Borges  | 29/08/2024 | Retirada a validação do l103Auto. Chamado 48274
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MTCOLSE2
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 29/12/2020
Descrição---------: Ponto de entrada para manipular os dados do aCols de títulos a pagar
Parametros--------: ParamIXB[1] -> A -> aCols das duplicatas
					ParamIXB[2] -> N -> 0 - Visualização do documento / 1 - Inclusão ou Classificação do documento
Retorno-----------: aColsE2 -> A -> aCols manipulado pelo usuário.
===============================================================================================================================
*/
User Function MTCOLSE2

Local _aArea    := FWGetArea()
Local _aAreaSDS := SDS->(GetArea())
Local _aColsE2  := ParamIXB[1] //aCols de duplicatas
Local _nOpc     := ParamIXB[2] //0-Tela de visualização / 1-Inclusão ou Classificação
Local _cXML     := ""
Local _oXML     := Nil
Local _cError	:= ''
Local _cWarning	:= ''
Local _lRet     := .F.

//lRefresh e FWIsInCallStack("NFEEMISSAO") -> evita que a rotina seja executada após o usuário realizar o ajuste e confirmar a inclusão, sobreponto um possível ajuste no vencimento
If _nOpc == 1 .And. cFormul == "N" .And. cTipo == "D" .And. l103GAuto .And. lRefresh .And. !FWIsInCallStack("NFEEMISSAO")
    DBSelectArea('CKO')
	CKO->( DBSetOrder(1) )
    SDS->( DBSetOrder(2) )
    If SDS->( DBSeek(xFilial("SDS")+aNFeDanfe[13] ) )
        CKO->( DBSeek( SDS->DS_ARQUIVO ) )
        _cXML := AllTrim( CKO->( CKO_XMLRET ) )
        //====================================================================================================
        // Processa se conseguir ler os dados do arquivo XML
        //====================================================================================================
        If !Empty( _cXML )
            _cXML := SubStr( _cXML , At( '<' , _cXML ) )
            //====================================================================================================
            // Inicializa o objeto do XML
            //====================================================================================================
            _oXML := XmlParser( _cXML , "_" , @_cError , @_cWarning )
            If !Empty(_oXml) .And. ValType(_oXml)=="O"
                If ValType(XmlChildEx(_oXml,"_NFEPROC")) == "O"
                    If ValType(XmlChildEx(_oXML:_NFeProc:_NFe:_InfNfe,"_COBR")) != "U"
                        If ValType(XmlChildEx(_oXML:_NFeProc:_NFe:_InfNfe:_cobr,"_DUP")) != "U"
                            _dVencto := SToD(StrTran(AllTrim(IIf(ValType(XmlChildEx(_oXML:_NFeProc:_NFe:_InfNfe:_cobr,"_DUP"))=="O",_oXML:_NFeProc:_NFe:_InfNfe:_cobr:_dup:_dVenc:Text,_oXML:_NFeProc:_NFe:_InfNfe:_cobr:_dup[1]:_dVenc:Text)),"-",""))
                            If _dVencto < dDataBase
                                _aColsE2[1][2] := dDataBase//Se já está vencida, usa a data atual
                                _lRet := .T.
                            Else
                                _aColsE2[1][2] :=_dVencto//Se não está vencida, usa o vencimento informado
                                _lRet := .T.
                            EndIf
                        EndIf
                    EndIf
                EndIf
            EndIf
        EndIf
    EndIf
    If !_lRet
        _aColsE2[1][2] := LastDay(MonthSum( dDatabase,1),1)//Primeiro dia útil do mês subsequente ao lançamento
    EndIf
    _oXML := Nil
    DelClassIntF()
EndIf

FWRestArea(_aAreaSDS)
FWRestArea(_aArea)

Return (_aColsE2)
