/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |11/03/2019| Chamado 28400. Alterado layout de importação.
Lucas Borges  |06/11/2023| Chamado 45424. Descontinuado o layout do TrackMaker e incluído do SmartQuestion
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FILEIO.CH"

/*
===============================================================================================================================
Programa----------: MGLT006
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 10/12/2018
Descrição---------: Rotina para importação de coordenadas geográficas para o cadastro de produtores
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGLT006()

Private _cPerg		:= "MGLT006"
Private _oSelf		:= nil

//============================================
//Cria interface principal
//============================================
tNewProcess():New(	_cPerg											,; // Função inicial
					"Atualiza Coord. Geográficas Produteres"		,; // Descrição da Rotina
					{|_oSelf| MGLT006P(_oSelf) }					,; // Função do processamento
					"Rotina para efetuar a atualização das coordenadas geográficas " +;
					"nos cadastros dos produtores rurais." ,; // Descrição da Funcionalidade
					_cPerg											,; // Configuração dos Parâmetros
					{}												,; // Opções adicionais para o painel lateral
					.F.												,; // Define criação do Painel auxiliar
					0												,; // Tamanho do Painel Auxiliar
					''												,; // Descrição do Painel Auxiliar
					.F.												,; // Se .T. exibe o painel de execução. Se falso, apenas executa a função sem exibir a régua de processamento.
                    .T.                                              ) // Se .T. cria apenas uma regua de processamento.

Return

/*
===============================================================================================================================
Programa----------: MGLT006P
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 10/12/2018
Descrição---------: Realiza o processamento da rotina.
Parametros--------: _oSelf
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT006P(_oSelf)

Local _cFilSMQT	:= SuperGetMV("LT_FILPROD", .F. ,"01,02,04,06,09,0A,0B,40,10,11,20,23,24,25") //filiais com integração com o SmartQuestion
Local _nHandle	:= 0
Local _aDados	:= {}
Local _cEOL 	:= CHR(13) + CHR(10)
Local _nBuffer	:= 100
Local _nFilePos	:= 0
Local _nPos		:= 0
Local _cLine	:= "" 
Local _cBuffer	:=''
Local _nTamArq	:= 0
Local _nProc	:= 0
Local _nSQ		:= 0
Local _nX		:= 0
Local _nLidos	:= 0

//Abre arquivo de texto
If (_nHandle := FOpen(MV_PAR01)) >= 0
    _oSelf:SetRegua1(1)
	_oSelf:IncRegua1("Abrindo arquivo...")
	_nTamArq:= FSeek(_nHandle, 0, 2) //Posiciona no fim do arquivo para pegar o tamanho
    _nFilePos:= FSeek(_nHandle, 0, 0) // Posiciona no início do arquivo, no primeiro caracter
	_oSelf:SetRegua1(_nTamArq)

	DBSelectArea("SA2")
	SA2->( DBSetOrder(1) )

	While !(_nFilePos < 0 .Or. _nFilePos >= _nTamArq)
	    _cBuffer	:= Space(_nBuffer) //Aloca Buffer
		FRead(_nHandle, _cBuffer, _nBuffer) //Lê os primeiros 100 caracteres do arquivo
		_nPos	:= AT(_cEOL, _cBuffer) // Procura o primeiro final de linha
		For _nX:= 1 To _nPos
			_oSelf:IncRegua1()
		Next _nX
		
	    If _nPos == 0
			MsgStop("Arquivo inconsistênte. Favor acionar o área de TI.","MGLT00601")
			Return
		EndIf	    	
	    // Leitura dos campos e gravação dos dados na tabela
	    _cLine := SubStr(_cBuffer, 0, _nPos)
		_aDados:= StrTokArr(_cLine,';')

		If SA2->( DBSeek( xFilial("SA2") + _aDados[1]))
			_nProc++
			SA2->( RecLock( "SA2" , .F. ) )
			SA2->A2_L_LATIT	:= NoRound(Val(StrTran(_aDados[2],",",".")),GetSx3Cache("A2_L_LONGI","X3_DECIMAL"))
			SA2->A2_L_LONGI	:= NoRound(Val(StrTran(_aDados[3],",",".")),GetSx3Cache("A2_L_LATIT","X3_DECIMAL"))
  			If SubStr( SA2->A2_L_LI_RO,1,2) $ _cFilSMQT
				_nSQ++
				SA2->A2_L_SMQST := 'P'
			EndIf
			SA2->( MSUnLock() )
		EndIf
		_nLidos+=_nPos+1 //Salvo até qual posição do arquivo já foi lido desde a primeira posição
		_nFilePos:=FSeek(_nHandle, _nLidos,0) //Posiciono na próxima linha a partir do início do arquivo
	EndDo
    
	If _nProc == 0
		MsgStop("Nenhum produtor foi atualizado.","MGLT00602")
	Else
		MsgInfo("Foram atualizados "+AllTrim(Str(_nProc))+" produtores com sucesso e "+AllTrim(Str(_nSQ))+" marcado(s) para envio para o SmartQuestion!","MGLT00603")
	EndIf

	// Fecha arquivo	
    FClose(_nHandle)
Else
	MsgAlert("O arquivo está vazio ou é inválido para análise! Verifique o arquivo e tente novamente.","MGLT00604")
EndIf

Return
