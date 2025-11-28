/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |22/10/2019| Chamado 30921. Tratamento para o campo NOVO CLAIM.
Alex Wallauer |19/02/2020| Chamado 32076. Correção do Tratamento do campo NOVO CLAIM.
Alex Wallauer |03/11/2021| Chamado 38128. Nova Validacao para E2_MSBLQL = '1' titulo bloqueado.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: F580LBA
Autor-------------: Guilherme D. Gesualdo
Data da Criacao---: 12/09/2012
Descrição---------: PE de validação de liberação automatica de baixa de titulo a pagar
Parametros--------: Nenhum
Retorno-----------: Lógico - Indicando se os dados foram validados ou não
===============================================================================================================================
*/
User Function F580LBA()

Local _aArea	:= FWGetArea()
Local aAreaSF1	:= SF1->(GetArea()) 
Local aAreaSD1	:= SD1->(GetArea())

//================================================================================
// QRYSE2 - TABELA TEMPORARIA CRIADA PELO FINA580 NA LIBERACAO AUTOMATICA
//================================================================================
Local _cCodFor	:= QRYSE2->E2_FORNECE
Local _cLojFor	:= QRYSE2->E2_LOJA
Local _cNumTit	:= QRYSE2->E2_NUM
Local _cPreTit	:= QRYSE2->E2_PREFIXO
Local _cMarca	:= QRYSE2->E2_OK //SE DIFERENTE DE "  " O REGISTRO ESTA MARCADO
Local _cTipo	:= ""
Local _lVldCTR	:= .F.
Local _lRet		:= .T.

If !Empty(_cMarca)

	_cTipo := Posicione( "SF1" , 1 , xFilial("SF1") + _cNumTit + _cPreTit + _cCodFor + _cLojFor , "F1_TIPO" )
	
	If _cTipo == "N" .And. !( SubStr(_cCodFor,1,1) $ "C/G" ) .And. !( Posicione("SA2",1,xFilial("SA2")+_cCodFor+_cLojFor,"A2_I_EXCTR") == "S")
		
		DBSelectArea("SD1")
		SD1->( DBSetOrder(1) )
		SD1->( DBSeek( xFilial("SD1") + _cNumTit + _cPreTit + _cCodFor + _cLojFor ) )
		
		While SD1->(!Eof()) .And. SD1->(D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA) == xFilial("SD1")+_cNumTit+_cPreTit+_cCodFor+_cLojFor
		
			//================================================================================
			// Verificar para os ítens com CFOP: 1352 ou 2352 e produto <> '10000000006'
			//================================================================================
			If ( AllTrim(SD1->D1_CF) == '1352' .Or. AllTrim(SD1->D1_CF) == '2352' ) .And. AllTrim(SD1->D1_COD) <> '10000000006'
				_lVldCTR := .T.
			EndIf
			
			//================================================================================
			// Verificar para os ítens com CFOP: 1933 ou 2933 e produto == '10000000023'
			//================================================================================
			If ( AllTrim(SD1->D1_CF) == '1933' .Or. AllTrim(SD1->D1_CF) == '2933' ) .And. AllTrim(SD1->D1_COD) == '10000000023'
				_lVldCTR := .T.
			EndIf
		
		SD1->( DBSkip() )
		EndDo
					
		If _lVldCTR 
			FWMsgRun( , {||  _lRet := u_validCTR( _cCodFor , _cLojFor , _cNumTit , _cPreTit )  }, "Aguarde....","Verificando lançamento do CTR..."  )
		EndIf
		
	EndIf

     If _lRet .And. QRYSE2->E2_I_CLAIM = "1"
     
         _lAcesso := U_ITVACESS( 'ZZL' , 3 , 'ZZL_CLAIM' , "S" )
     
         If !_lAcesso
     
     	    U_ITMsg('Usuário sem permissão para liberar titulos com Claim = Sim',"ATENÇÃO",;
     		   	    'Caso necessário solicite a manutenção à um usuário com acesso ou, se necessário, solicite o acesso à área de TI/ERP.', 1  )
             _lRet := .F.
     	
          EndIf
     
     EndIf
     
     If _lRet .And. QRYSE2->E2_MSBLQL = "1"
     
        U_ITMsg('Não é possivel liberar o Titulo por que se encontra Bloqueado',"ATENÇÃO",;
     	  	    'Solicite o desbloqueio do Titulo para Gestor da Area.', 1  )
        _lRet := .F.
     
     EndIf

EndIf


FWRestArea(_aArea)
FWRestArea(aAreaSF1)
FWRestArea(aAreaSD1)

Return( _lRet )

