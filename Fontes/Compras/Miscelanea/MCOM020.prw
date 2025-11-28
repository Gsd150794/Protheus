/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |30/09/2024| Chamado 48677. Corrigida validação do objeto
Lucas Borges  |23/05/2025| Chamado 50754. Incluído tratamento para CT-e Simplificado
Lucas Borges  |27/11/2025| Chamado 53171. Incluída notificação por e-mail quando algum XML é carregado.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MCOM020
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 13/10/2023
Descrição---------: Rotina para carregar XMLs para o TOTVS Colaboração. Chamado 45321
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCOM020()

Local _cPerg    := "MCOM020" As Character
Local _oSelf    := nil As Object

//============================================
//Cria interface principal
//============================================
tNewProcess():New(	_cPerg											,; // Função inicial
					"Carrega XMLs"							,; // Descrição da Rotina
					{|_oSelf| MCOM020P(_oSelf) }					,; // Função do processamento
					"Essa rotina permite fazer upload de arquivos XMLs para a fila de processamento do TOTVS Colaboração."+CRLF+;
					"Ela deve der utilizada apenas em casos excepcionais.",; // Descrição da Funcionalidade
					_cPerg											,; // Configuração dos Parâmetros
					{}												,; // Opções adicionais para o painel lateral
					.F.												,; // Define criação do Painel auxiliar
					0												,; // Tamanho do Painel Auxiliar
					''												,; // Descrição do Painel Auxiliar
					.T.												,; // Se .T. exibe o painel de execução. Se falso, apenas executa a função sem exibir a régua de processamento.
                    .T.                                             ,; // Se .T. cria apenas uma regua de processamento.
                    .T.                                              ) //Se .T. habilita o botão de processamento em segundo plano (execução ocorre pelo Scheduler)

Return
/*
===============================================================================================================================
Programa----------: MGLT020P
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 13/10/2023
Descrição---------: Realiza o processamento da rotina.
Parametros--------: _oSelf
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MCOM020P(_oSelf As Object)

Local _aArea 	:= FWGetArea() As Array
Local _aAreaSF1 := SF1->(FWGetArea()) As Array
Local _aAreaCKO := CKO->(FWGetArea()) As Array
Local _lRet  	:= .F. As Logical
Local _cArquiv 	:= '' As Character
Local _cChaveCKO:= '' As Character
Local _cEspecie := '' As Character
Local _cChaveNFe:= '' As Character
Local _cURL     := PadR(GetNewPar("MV_SPEDURL","http://"),250) As Character
Local _cIdEnt   := '' As Character
Local _cDirOri  := AllTrim(MV_PAR01) As Character
Local _cDestino := SuperGetMV("IT_DIRORI",.F.,"\system") As Character
Local _oArquivo := Nil As Object
Local _oXML		:= Nil As Object
Local _oFullXML	:= Nil As Object
Local _oFile 	:= Nil As Object
Local _cXML  	:= Nil As Character
Local _nX 		:= 0 As Numeric
Local _cError	:= ' ' As Character
Local _cWarning	:= ' ' As Character
Local _cCodRet	:= "Codigo de retorno: " As Character
Local _cMensRet := "Mensagem de retorno: " As Character
Local _cMensagem:= "" As Character
Local _cErro    := "" As Character
Local _cTO      := SuperGetMV("IT_MCOM020",.F.,"") As Character

DBSelectArea("SF1")
SF1->(DBSetOrder(8))
DBSelectArea("CKO")
CKO->(DBSetOrder(1))

//Verifica se o servidor da Totvs esta no ar
oWs := WsSpedCfgNFe():New()
oWs:cUserToken := "TOTVS"
oWS:_URL := AllTrim(_cURL)+"/SPEDCFGNFe.apw"

If oWs:CFGCONNECT()
	
    //Obtem o codigo da entidade
    If FindFunction("getCfgEntidade") 
        _cIdEnt := getCfgEntidade(@_cError)
    Else 
        _cError := "Função getCfgEntidade não localizada no RPO!"
    EndIf
    If !Empty(_cError)
        FWAlertWarning(_cError,"MCOM02001")
    EndIf  
    oWs:= WsNFeSBra():New()
    oWs:cUserToken   := "TOTVS"
    oWs:cID_ENT      := _cIdEnt
    ows:cCHVNFE		 := _cChaveNFe
    oWs:_URL         := AllTrim(_cURL)+"/NFeSBRA.apw"

    _aFiles := Directory(_cDirOri + "*.xml")

    If !Empty(_aFiles)
        _cXML  := Space(0)
        _oSelf:SetRegua1(Len(_aFiles))
        For _nX := 1 To Len(_aFiles)
            _oSelf:IncRegua1("Importando arquivo "+ _aFiles[_nX][1])
            _oFile := FwFileReader():New(_cDirOri+_aFiles[_nX][1])
            _lRet := .F.
            //Realiza a leitura do arquivo
            If _oFile:Open()
                _cXML := _oFile:FullRead()
                _oFile:Close()
            Else
                FWAlertWarning("Não foi possível abrir o arquivo "+_aFiles[_nX][1]+". Ele será ignorado. Erro: "+ _oFile:Error():Message,"MCOM02002")
                Loop
            EndIf
            _cXML := SubStr( _cXML , At( '<' , _cXML ) )
            // Inicializa o objeto do XML
            _oFullXML := XmlParser( _cXML , "_" , @_cError , @_cWarning )
            _cEspecie:= 'CTE'

            If ValType( XmlChildEx( _oFullXML , "_NFEPROC" ) ) == "O" //-- Nota normal, devolucao, beneficiamento, bonificacao
                If ValType( XmlChildEx( _oFullXML:_NFeProc , "_NFE" ) ) == "O"
                    _oXML := _oFullXML:_NFeProc:_Nfe    
                Else
                    _oXML := _oFullXML:_NFeProc:_NFeProc:_Nfe
                EndIf
                _cChaveNFe := Right(AllTrim(_oXML:_InfNfe:_Id:Text),44)
                _cEspecie:= 'SPED'
                _cChaveCKO:= '109'+_cChaveNFe+'.xml'
                _cArquiv:= 'NFE'+_cChaveNFe+'.xml'
            ElseIf ValType(XmlChildEx(_oFullXML,"_CTE")) == "O" //-- Nota de transporte
                _oXML := _oFullXML:_CTe
                _cChaveNFe := Right(AllTrim(_oXML:_InfCte:_Id:Text),44)
            ElseIf ValType(XmlChildEx(_oFullXML,"_CTESIMPPROC")) == "O"
                _oXML := _oFullXML:_CTeSimpProc:_CTeSimp
                _cChaveNFe := Right(AllTrim(_oXML:_InfCte:_Id:Text),44)
            ElseIf ValType(XmlChildEx(_oFullXML,"_CTEPROC")) == "O" //-- Nota de transporte
                If ValType(XmlChildEx(_oFullXML:_CTEPROC,"_ENVICTE")) == "O"
                    _oXML := _oFullXML:_CTeProc:_ENVICTE:_Cte
                ElseIf ValType(XmlChildEx(_oFullXML:_CTEPROC,"_CTEOS")) == "O" //-- Nota de transporte CTEOS
                    _oXML := _oFullXML:_CTeProc:_CTEOS
                    _cEspecie:= 'CTEOS'
                Else
                    _oXML := _oFullXML:_CTeProc:_Cte
                EndIf
                _cChaveNFe := Right(AllTrim(_oXML:_InfCte:_Id:Text),44)
            ElseIf ValType(XmlChildEx(_oFullXML,"_CTEOSPROC")) == "O" //-- Nota de transporte CTEOS
                _oXML := _oFullXML:_CTeOSProc:_CteOS
                _cEspecie:= 'CTEOS'
                _cChaveNFe := Right(AllTrim(_oXML:_InfCte:_Id:Text),44)
            EndIf
            If _cEspecie == 'CTEOS'
                _cChaveCKO:= '273'+_cChaveNFe+'.xml'
                _cArquiv:= 'CTE'+_cChaveNFe+'.xml'
            ElseIf _cEspecie == 'CTE'
                _cChaveCKO:= '214'+_cChaveNFe+'.xml'
                _cArquiv:= 'CTE'+_cChaveNFe+'.xml'
            EndIf
            
            //Verifica se documento já foi gerado
            If SF1->(DBSeek(xFilial("SF1") + _cChaveNFe)) .Or. CKO->(DBSeek(_cChaveCKO))
                FWAlertWarning("Chave informada já consta no sistema e será ignorada: "+_aFiles[_nX][1],"MCOM02003")
                Loop
            EndIf

            ows:cCHVNFE := _cChaveNFe
            If oWS:ConsultaChaveNFE()
                If oWs:oWSCONSULTACHAVENFERESULT:cPROTOCOLO == Nil .Or. Empty (oWs:oWSCONSULTACHAVENFERESULT:cPROTOCOLO)
					If AllTrim(oWs:oWSCONSULTACHAVENFERESULT:cCODRETNFE) == "731" .Or. AllTrim(oWs:oWSCONSULTACHAVENFERESULT:cCODRETNFE) == "526"
                        If MsgNoYes(_cCodRet+oWs:oWSCONSULTACHAVENFERESULT:cCODRETNFE+CRLF+;
                                    _cMensRet+oWs:oWSCONSULTACHAVENFERESULT:cMSGRETNFE+CRLF+;
                                    "Verificar se o Ano-Mês da Chave de Acesso está com atraso"+CRLF+;
                                    "superior a 6 meses em relação ao Ano-Mês atual."+CRLF+CRLF+CRLF+;
                                    "Deseja inserir a chave mesmo assim?")
                            _lRet := .T.
                        Else
                            _lRet := .F.
                        EndIf
					ElseIf AllTrim(oWs:oWSCONSULTACHAVENFERESULT:cCODRETNFE) == "101" .Or. AllTrim(oWs:oWSCONSULTACHAVENFERESULT:cCODRETNFE) == "151"
						FWAlertHelp("  ",1,"MCOM02005",,_cCodRet+oWs:oWSCONSULTACHAVENFERESULT:cCODRETNFE+CRLF+;
				   		       _cMensRet+oWs:oWSCONSULTACHAVENFERESULT:cMSGRETNFE+CRLF+CRLF+_cChaveNFe,1,0)
						_lRet := .F.
					Else
						FWAlertWarning("A chave digitada não foi encontrada na Sefaz ("+_aFiles[_nX][1]+"), favor verificar","MCOM02006")
						_lRet := .F.
					EndIf
				Else
				    If AllTrim(oWs:oWSCONSULTACHAVENFERESULT:cCODRETNFE) == "101" .Or. AllTrim(oWs:oWSCONSULTACHAVENFERESULT:cCODRETNFE) == "151"
						FWAlertHelp("  ",1,"MCOM02007",,_cCodRet+oWs:oWSCONSULTACHAVENFERESULT:cCODRETNFE+CRLF+;
				   		       _cMensRet+oWs:oWSCONSULTACHAVENFERESULT:cMSGRETNFE+CRLF+CRLF+_cChaveNFe,1,0)
						_lRet := .F.
					Else
						_lRet := .T.
					EndIf
				EndIf

                If _lRet
                    _oArquivo:= FWFileWriter():New(_cDestino+"\"+_cArquiv)
                    _oArquivo:SetEncodeUTF8(.T.)
                    If _oArquivo:Create()
                        _oArquivo:Write(AllTrim(_cXml))
                        _oArquivo:Close()
                        If _oArquivo:Exists()
                            FWAlertInfo("Documento incluído na fila para processamento: "+_aFiles[_nX][1]+".",'MCOM02008')
                            _oSelf:SaveLog("Documento incluído na fila para processamento: "+_aFiles[_nX][1]+".")
                            _cMensagem:="Documento incluído na fila para processamento: "+_cArquiv+". Usuário: " + __cUserId + ' - '+ cUserName
                            U_EnvMail(_cMensagem/*_cMensagem*/,/*_cFrom*/,_cTO/*_cTO*/,/*_cCC*/,/*_cBCC*/,/*_cReplyTo*/,'MCOM020 - Upload manual de XML'/*_cAssunto*/,@_cErro/*_cErro*/,/*_aAttach*/)
                            If !Empty(_cErro)
                                FWAlertError("Erro ao enviar o e-mail de notificação. Acione o Suporte!","MCOM02012")
                            EndIf
                        EndIf
                    Else
                        FWAlertError("Erro na criação do arquivo XML no Servidor: "+_aFiles[_nX][1]+". Ele será ignorado. Erro: "+ _oArquivo:Error():Message,"MCOM02009")
                    EndIf
                    FreeObj(_oArquivo)
                EndIf
            Else
                FWAlertWarning("Erro ao consultar chave do arquivo "+_aFiles[_nX][1]+". Ele será ignorado. "+IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),"MCOM02010") 
            EndIf
        Next _nX
    Else
        FWAlertInfo("Não foram localizados arquivos XMLs.","MCOM02011")
    EndIf
Else
	FWAlertHelp(" ",1,"TSSINATIVO")
EndIf

_oXML := Nil
_oFullXML:= Nil
DelClassIntF()

FWRestArea(_aAreaSF1)
FWRestArea(_aAreaCKO)
FWRestArea(_aArea)

Return
