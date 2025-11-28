/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |25/08/2023| Chamado 44786. Tratamento para o novo tipo Familiar - A2_L_CLASS == 'F'.
Lucas Borges  |24/07/2025| Chamado 51340. Ajustar função para validação de ambiente de teste
Lucas Borges  |14/09/2025| Chamado 51799. Implementada função para validar ambiente de teste totvs.framework.environment.Type.get()
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include 'FWMVCDef.ch'
#Include 'XMLXFUN.ch'
#Include 'FileIO.ch'

/*
===============================================================================================================================
Programa----------: MGLT001
Autor-------------: Alexandre Villar
Data da Criacao---: 04/05/2015
Descrição---------: Rotina de Integração via WebService de integração dos Produtores para o SmartQuestion
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGLT001(_lLIntMedVol)

Local _lExecInt	  := .F.,D
Private _aDados	  := {}
Private _lSchedule:= .F.

U_ITCONOUT( 'Inicializando o processamento da integração dos Produtores para o SmartQuestion' )

If ValType(_lLIntMedVol) <> "L"
   _lIntMedVol:=.F.
Else
   _lIntMedVol:=_lLIntMedVol
EndIf
// Inicializar o ambiente para chamada via schedule
_lSchedule := ( Select("SX3") <= 0 )
_nOpcao   := 2
_cFiltroFilial:= ""
_cSetorI := ""
_cSetorF := ""
_dDataI  := DATE()-8
_dDataF  := DATE()-1

If _lSchedule
	
	U_ITCONOUT( 'Abrindo o ambiente...' )
	
	RPCSetType(3)
	RpcSetEnv( "01" , "01" ,,,, "SCHEDULE_WF_SOLICITACAO" , {'SA2','ZL2','ZLT','ZLS','CC2'} )
	Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações Do ambiente.

    _cFiltroFilial:= SuperGetMV("LT_FILPROD",.F.,"01;02;04;06;09;0A;0B;40;10;11;20;23;24;25")
    
Else

    If (_nOpcao:=AVISO("MGLT00101 - Envia Produtores para o SQ", "Confirma Processamento Do envio para o Smartquestion?",;
	                   { "Envia Teste"  ,;      // 01 - Envia para o ambinte de testes: http://teste.smartquestion.com.br/italac/
					     "Envia Oficial",;      // 02
						 "Envia Todos"  ,;      // 03 - Pergunte("AGLT021")
						  "Cancela"}    ,2)) = 4// 04 , "Envia Oficial v13"  
       Return .F.
    EndIf

    If _nOpcao = 3 //.OR. _nOpcao = 2 //"Envia Todos" OU Envia Oficial
       If !Pergunte("AGLT021")
          Return .F.
       EndIf
       _cFiltroFilial:= AllTrim(MV_PAR01)
       _cSetorI := MV_PAR04
       _cSetorF := MV_PAR05

       If Empty(_cFiltroFilial)
          _cFiltroFilial:= SuperGetMV("LT_FILPROD",.F.,"01;02;04;06;09;0A;0B;40;10;11;20;23;24;25")
       EndIf
       If !Empty(MV_PAR02)
          _dDataI:= MV_PAR02
       EndIf
       If !Empty(MV_PAR03)
          _dDataF:= MV_PAR03
       EndIf
       If MV_PAR12 = '1'
          _lIntMedVol:=.T.
       EndIf
    EndIf
                                     
EndIf

_cWS:=SuperGetMV("LT_WSS_END",.F.,"italac.smartquestion.com.br/ws/WsSmartQuestionV14NoMtom?wsdl")//italac.smartquestion.com.br/ws/WsSmartQuestionv13?wsdl
_cVerAtual:="v14"

_cTimeInicial:=Time()

If !totvs.framework.environment.Type.get() == '1' .Or. _nOpcao = 1//"ENVIA TESTE" //1-Produção, 2-Homologação,3-Desenvolvimento
   _cWS:='http://teste.smartquestion.com.br/italac/ws/WsSmartQuestionV14NoMtom?wsdl'
   _cVerAtual:="v14"
EndIf

U_ITCONOUT( 'Envio direcionado para: '+_cWS )

// Leitura inicial dos parâmetros
_lExecInt	:= SuperGetMV("LT_INT_SMQ",.F.,.T.)

If !_lExecInt
	U_ITCONOUT( 'Rotina não está habilitada no parâmetro "LT_INT_SMQ".' )
	Return
EndIf

U_ITCONOUT( 'Consultando os dados para o processamento...' )

// Monta a estrutura de dados Do arquivo
If _lSchedule
   _aDados := MGLT001GET()
Else

   FWMsgRun(,{ |_oProc| _aDados := MGLT001GET(_oProc) },'Filtrando dados...',"Aguarde...")

EndIf

If Empty(_aDados) 

   If _lSchedule
      U_ITCONOUT( 'Não foram encontrados registros pendentes para processar.' )
   Else
      MsgStop("Não foram encontrados registros pendentes para processar.","MGLT00102")
   EndIf

Else
	
   If _nOpcao = 3//"Envia Todos"
      aSort(_aDados,,,{ |X,Y| X[26]+X[21] < Y[26]+Y[21] })
   Else
      aSort(_aDados,,,{ |X,Y| X[21]+X[22] < Y[21]+Y[22] })
   EndIf
   _aLog:=aClone(_aDados)
   
   For D := 1 To Len(_aLog)
       aSize(_aLog[D] , Len(_aLog[D])+1 )
       aIns(_aLog[D] , 1 )//Inseri um acoluna no inicio de controle
       If Empty(_aLog[D][26])
          _aLog[D,1]:=.T.//Marca
       Else
          _aLog[D,1]:=.F.//Não Marca
       EndIf
   Next

   If !_lSchedule
      _aButtons:={}
      aAdd( _aButtons , { "Envia Email"	, {|| FWMsgRun(,{ |_oProc| MGLT001EML("",_aLog,.T.,_oProc) },'Filtrando dados...',"Aguarde...")  }, "Envia Email Do Log","Envia Email"} )

      aCab:={"","Cod. Produtor","Nome Produtor","Latitude","Longitude","Ativo","Endereco","Bairro","Código município","Nome município","Nome Estado",;
	         "Sigla Estado","E-mail","Telefone","Tipo Ponto","Código Setor","Descrição Setor","Código Linha/Rota","Código Empresa","Nome Empresa",;
			 "Descrição Setor","Tipo","Cod. Tanque","Cod. Produtor","Comparação","Mensagens de validações de erros cadastrais","Ordem","Setor",;
			 "Media de Volume","Sit","CPF","NIRF","SIG_SIF","Nome Secundario"}
      _cTitAux:='Log de Leitura - Integração SQ '+_cVerAtual+' - '+If(_nOpcao = 1,"Envia Site Teste","Envia Site Oficial")+" - Lidos: "+AllTrim(Str(Len(_aLog)))
      _cTit1Aux:=" - Parametro: LT_WSS_END = "+_cWS
        //    ITListBox(_cTitAux , _aHeader, _aCols ,_lMaxSiz,_nTipo,_cMsgTop , _lSelUnc , _aSizes, _nCampo ) 
      lRet:=U_ITListBox(_cTitAux , aCab    , _aLog  , .T.    , 2    ,_cTitAux+_cTit1Aux ,          ,         ,        ,,, _aButtons)
      If !lRet .Or. Empty(_aDados)
         Return .F.
      EndIf    
   EndIf

   If _lSchedule
      MGLT1Envia()
   Else
      FWMsgRun(,{ |_oProc| MGLT1Envia(_oProc) } , 'Aguarde!' , 'Enviando dados...' )
   EndIf

EndIf

Return .T.

/*
===============================================================================================================================
Programa--------: MGLT001GET
Autor-----------: Alexandre Villar
Data da Criacao-: 04/05/2015
Descrição-------: Monta os dados para preenchimento das informações no XML de integração de produtores
Parametros------: Nenhum
Retorno---------: _aDados - Dados para montagem no XML de acordo com o Fornecedor posicionado
===============================================================================================================================
*/
Static Function MGLT001GET(_oProc)

Local _cQuery	 := ''
Local _cAlias	 := GetNextAlias()
Local _aDados	 := Array(30)
Local _aRet		 := {}
Local _cSeparador:= ";"

If "," $ _cFiltroFilial
   _cSeparador:= ","
EndIf

If !_lSchedule
    _oProc:cCaption := ("Filtrando os dados conforme seleção, Aguarde...")
    ProcessMessages()
EndIf

_cQuery := " SELECT SA2.R_E_C_N_O_ AS REGSA2 "
_cQuery += " FROM  "+ RetSqlName('SA2') +" SA2 "
_cQuery += " WHERE "+ RetSqlCond('SA2')
_cQuery += " AND SubStr( SA2.A2_COD , 1 , 1 ) = 'P' "
_cQuery += " AND SA2.A2_I_CLASS = 'P' "
_cQuery += " AND SA2.A2_L_LI_RO <> ' ' "
If !Empty(_cFiltroFilial)
   _cQuery += " AND SubStr(SA2.A2_L_LI_RO, 1 , 2 ) IN "+FormatIn(_cFiltroFilial,_cSeparador)
EndIf
If (_nOpcao = 3 .Or. _lIntMedVol) .And. _lSchedule////"Envia Todos" OU MV_PAR12 = '1'
   _cQuery += " AND (SA2.A2_L_CLASS =  'U' OR SA2.A2_L_CLASS =  'C' ) "//OR SA2.A2_L_CLASS =  'F'
   _cQuery += " AND (SA2.A2_L_CLASS <> 'U' OR (SA2.A2_L_TANQ <> ' ' AND SA2.A2_L_TANLJ <> ' ')) "
   _cQuery += " AND (SA2.A2_L_CLASS <> 'U' OR (SA2.A2_L_TANQ <> SA2.A2_COD)) "
   _cQuery += " AND (SA2.A2_L_CLASS <> 'C' OR (SA2.A2_L_TANQ =  SA2.A2_COD AND SA2.A2_L_TANLJ = SA2.A2_LOJA)) "
   _cQuery += " AND (SA2.A2_MSBLQL <> '1' AND SA2.A2_L_ATIVO =  'S') "
   If _lIntMedVol // MV_PAR12 = '1'
      _cQuery += " AND SA2.A2_L_SMQST <> 'P' "
   EndIf   
Else
   If _lIntMedVol// MV_PAR12 = '1'
      _cQuery += " AND SA2.A2_L_SMQST <> 'P' "
   Else   
      _cQuery += " AND SA2.A2_L_SMQST = 'P' "
   EndIf   
EndIf
_cQuery += " ORDER BY SA2.A2_L_LI_RO , SA2.A2_COD "
If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T., .F. )

_nCount:=0
Count To _nCount
_cTotal:=AllTrim(Str(_nCount))
_nTam:=Len(_cTotal)+1
_nCount:=0

U_ITCONOUT( 'Validando '+_cTotal +' registros...' )
ZL3->( DBSetOrder(1) )
ZL2->( DBSetOrder(1) )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
_cAliasSA2:="SA2"//_cAlias
While (_cAlias)->( !Eof() )
	
   (_cAliasSA2)->( DBGoTo( (_cAlias)->REGSA2 ) )

   _nCount++
   If !_lSchedule
       _oProc:cCaption := ("Lendo produtor "+SubStr( (_cAliasSA2)->A2_L_LI_RO , 1 , 2 )+" "+(_cAliasSA2)->( A2_COD + A2_LOJA )+" : "+Str(_nCount,_nTam)+" de "+_cTotal )
       ProcessMessages()
   EndIf
   
   If !Empty(_cFiltroFilial) .And. !SubStr( (_cAliasSA2)->A2_L_LI_RO , 1 , 2 ) $ _cFiltroFilial
      (_cAlias)->( DBSkip() )
      Loop
   EndIf

   If ZL3->( DBSeek( SubStr( (_cAliasSA2)->A2_L_LI_RO , 1 , 2 ) + (_cAliasSA2)->A2_L_LI_RO ) )
	
	  If !Empty(_cSetorI) .And. ZL3->ZL3_SETOR < _cSetorI  
         (_cAlias)->( DBSkip() )
         Loop
	  EndIf

	  If !Empty(_cSetorF) .And. ZL3->ZL3_SETOR > _cSetorF
         (_cAlias)->( DBSkip() )
         Loop
	  EndIf

	  If ZL2->( DBSeek( SubStr( ZL3->ZL3_SETOR , 1 , 2 ) + ZL3->ZL3_SETOR ) )
	        
	        _aDados	:= Array(33)	
			/* codigo Produtor		*/ _aDados[01] := (_cAliasSA2)->( A2_COD + A2_LOJA )
            If _nOpcao = 1 .Or. !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
			/* nome Produtor		*/ _aDados[02] := AllTrim( (_cAliasSA2)->A2_NOME)+" TST Alex TI"//+"-T"//ST: "//+AllTrim(cUserName)+")" //TIRAR
			Else
			/* nome Produtor		*/ _aDados[02] := AllTrim( (_cAliasSA2)->A2_NOME	)
			EndIf
			/* Latitude				*/ _aDados[03] := cValToChar( (_cAliasSA2)->A2_L_LATIT )
			/* Longitude			*/ _aDados[04] := cValToChar( (_cAliasSA2)->A2_L_LONGI )
			/* Ativo				*/ _aDados[05] := IIf( (_cAliasSA2)->A2_MSBLQL <> '1' .And. (_cAliasSA2)->A2_L_ATIVO == 'S' , 'true' , 'false' )
			/* Endereco				*/ _aDados[06] := AllTrim( (_cAliasSA2)->A2_END +" "+ (_cAliasSA2)->A2_COMPLEM )
			/* Bairro				*/ _aDados[07] := AllTrim( (_cAliasSA2)->A2_BAIRRO )
			/* Código município		*/ _aDados[08] := (_cAliasSA2)->( A2_EST + A2_COD_MUN )
			/* Nome município		*/ _aDados[09] := AllTrim( Posicione('CC2',1,xFilial('CC2')+(_cAliasSA2)->( A2_EST + A2_COD_MUN ),'CC2_MUN') )
			/* Nome Estado			*/ _aDados[10] := Capital( AllTrim( Posicione( 'SX5' , 1 , xFilial('SX5') + '12' + (_cAliasSA2)->A2_EST , "X5_DESCRI" ) ) )
			/* Sigla Estado			*/ _aDados[11] := (_cAliasSA2)->A2_EST
			/* E-mail				*/ _aDados[12] := AllTrim( (_cAliasSA2)->A2_EMAIL )
			/* Telefone				*/ _aDados[13] := PadL( AllTrim( (_cAliasSA2)->A2_DDD ) , 2 ) + AllTrim( (_cAliasSA2)->A2_TEL )
			/* Tipo Ponto			*/ _aDados[14] := If( (_cAliasSA2)->A2_L_CLASS == 'U' , '000002' ,If( (_cAliasSA2)->A2_L_CLASS == 'C' ,   '000003' , If( (_cAliasSA2)->A2_L_CLASS == 'F' ,   '000004' , '000001' )) )
			/* Código Setor			*/ _aDados[15] := ZL2->ZL2_COD
			/* Descrição Setor		*/ _aDados[16] := AllTrim( ZL2->ZL2_DESCRI )
			/* Código Linha/Rota	*/ _aDados[17] := SubStr( (_cAliasSA2)->A2_L_LI_RO , 1 , 2 )
			/* Código Empresa		*/ _aDados[18] := '01'
			/* Nome Empresa			*/ _aDados[19] := 'Italac'
			/* Descrição Setor		*/ _aDados[20] := (_cAliasSA2)->A2_L_LI_RO
			/* Tipo           		*/ _aDados[21] := If( (_cAliasSA2)->A2_L_CLASS == 'U' , '2-Usuario TC' ,If( (_cAliasSA2)->A2_L_CLASS == 'C' ,  '1-Coletivo' ,If( (_cAliasSA2)->A2_L_CLASS == 'F' ,   '4-Familiar   ' ,  "3-Individual ")) )
			/* Código Tanque		*/ _aDados[22] := If( !Empty((_cAliasSA2)->A2_L_TANQ) .And. !Empty((_cAliasSA2)->A2_L_TANLJ) .And. !(_cAliasSA2)->( A2_COD + A2_LOJA ) == (_cAliasSA2)->A2_L_TANQ+(_cAliasSA2)->A2_L_TANLJ , (_cAliasSA2)->A2_L_TANQ+(_cAliasSA2)->A2_L_TANLJ,"")
			/* Código Produtor		*/ _aDados[23] := (_cAliasSA2)->( A2_COD + A2_LOJA )
			/* Comparação        	*/ _aDados[24] := If((_cAliasSA2)->( A2_COD + A2_LOJA ) == (_cAliasSA2)->A2_L_TANQ+(_cAliasSA2)->A2_L_TANLJ," = "," # " )
			/* Erro              	*/ _aDados[25] := ""//Reservado para os erro da integração
			/* Para ordernar     	*/ _aDados[26] := If( (_cAliasSA2)->A2_L_CLASS $ 'U,F' , (_cAliasSA2)->A2_L_TANQ+(_cAliasSA2)->A2_L_TANLJ ,If( (_cAliasSA2)->A2_L_CLASS == 'C' ,  (_cAliasSA2)->( A2_COD + A2_LOJA ) , "") )
			/* Setor             	*/ _aDados[27] := ZL3->ZL3_SETOR
			/* Média de Volume      */ _aDados[28] := U_MedVol( (_cAliasSA2)->A2_L_TIPPR , _dDataI , _dDataF , (_cAliasSA2)->A2_COD , (_cAliasSA2)->A2_LOJA  )
			/* Acaito=B Rejeitado=A */ _aDados[29] := "A"
			/* CPF                  */ _aDados[30] :=  (_cAliasSA2)->A2_CGC    //NOVO 14/04/2021
			/* NIRF                 */ _aDados[31] :=  (_cAliasSA2)->A2_L_NIRF //NOVO 14/04/2021
			/* SIG_SIF              */ _aDados[32] :=  (_cAliasSA2)->A2_L_SIGSI//NOVO 14/04/2021
			/* NOME_SECUNDARIO      */ _aDados[33] :=  (_cAliasSA2)->A2_L_NATRA//NOVO 04/08/2021
			//SE For POR MAIS CAMPOS AUMENTE A ARRAY(33) da _aDados NA LINHA 303 ACIMA e não esqueça de por o titulo do campo na array 
			//de titulos aCab (2 lugares linha 588 e 179) de campo senão dá erro na opção do menu "Exp. XML"
		    //====================================================================================================
		    // Validações antes de enviar

	        If Empty((_cAliasSA2)->A2_L_TANQ) 
	           _aDados[25]+="-Cód. Do responsavel pelo Tanque desse produtor NÃO esta preenchido. -Solução: ele deve ser peenchido."

	        ElseIf Left(_aDados[21],1) $ "1,3" .And. _aDados[24] == " # "//Coletivo e Individual
	           _cMenAux:=If(Left(_aDados[21],1)="1","Tanque Coletivo","Individual")
	           _aDados[25]+="-O produtor ["+_aDados[1]+"], está como "+_cMenAux+", e tem um Cód. Tanque DIFERENTE dele mesmo. -Soluções: Se o produtor For "+_cMenAux+", alterar o Cód. Tanque, colocando o mesmo Do próprio produtor, OU Se o produtor For Usuário de Tanque, alterar a classificação Do produtor para Usuário de Tanque."

	        ElseIf Left(_aDados[21],1) $ "2" .And. _aDados[24] == " = "//Familiar e Usuário de Tanque
	           _cMenAux:="Usuário de Tanque"//If(Left(_aDados[21],1)="4","Tanque Familiar","Usuário de Tanque")
	           _aDados[25]+="-O produtor ["+_aDados[1]+"] está como "+_cMenAux+", e tem um Cód. Tanque IGUAL ao dele mesmo. -Soluções: Se o produtor For "+_cMenAux+", alterar o Cód. Tanque indicando o produtor responsável pelo taque, OU Se o produtor For Individual, alterar a classificação Do produtor para Individual."
			
			ElseIf !Empty(_aDados[22]) .And. SA2->( DBSeek( xFilial('SA2') + _aDados[22] ) )//Validando o tanque do "Usuario de Tanque" e "Familiar"
			   //Só entra aqui se: 
               If !SA2->A2_L_CLASS $ 'C,F'//Tanque coletivo
	              _cMenAux:=If(Left(_aDados[21],1)="4","Tanque Familiar","Tanque Coletivo")
	              _aDados[25]+="-A classificação Do responsável pelo tanque NÃO é "+_cMenAux+" [Cód. Resp.Tanque: "+_aDados[22]+"]. -Solução: Alterar a classificação Do responsável pelo tanque para "+Upper(_cMenAux)+"."+CRLF
	           EndIf
               If !SA2->( A2_COD + A2_LOJA ) == SA2->A2_L_TANQ+SA2->A2_L_TANLJ
	              _aDados[25]+="-O responsável pelo tanque ["+_aDados[22]+"] está com o campo Cód. Tanque DIFERENTE dele mesmo. -Solução: Alterar cód. tanque, colocando o mesmo Do próprio produtor. Eles devem ser iguais."
	           EndIf
			EndIf

	        If !Empty( _aDados )
               aAdd( _aRet , _aDados )
            EndIf
	
		EndIf
	
	EndIf
	
(_cAlias)->( DBSkip() )
EndDo

ZLW->( DBSetOrder(1) )
ZLD->( DBSetOrder(1) )

Return( _aRet )

/*
===============================================================================================================================
Programa--------: MGLT1Envia()
Autor-----------: Alex Wallauer
Data da Criacao-: 08/03/2017
Descrição-------: Envia os dados para o SQ
Parametros------: Nenhum
Retorno---------: .T.
===============================================================================================================================
*/
Static Function MGLT1Envia(_oProc)

Local _aDadLog	:= {}
Local _cXml	  	:= ''
Local _cXmlRet	:= ''
Local _nI		:= 0
Local _cErro	:= ''
Local _cMetodo	:= 'ENV_PRODUTOR'
Local _cTotal:=AllTrim(Str(Len( _aDados )))
Local _nTam:=Len(_cTotal)+1
Local _cCodUsr	:= IIf( _lSchedule, "SCHEDU", RetCodUsr()) //Para gravação no U_ITGrvLog()
U_ITCONOUT( 'Enviando '+ _cTotal +' registros...' )

_nCount:=0
_nAceitos:=0
Begin Sequence

	SA2->( DBSetOrder(1) )
	For _nI := 1 To Len( _aDados )

        _nCount++
        If !_lSchedule
           _oProc:cCaption := ("Enviando produtor "+_aDados[_nI][17]+" "+_aDados[_nI][01]+" : "+Str(_nCount,_nTam)+" de "+_cTotal+" - Aceitos: "+Str(_nAceitos,_nTam) )
           ProcessMessages()
        EndIf

	    If !_aLog[_nI][01] .Or. !Empty(_aLog[_nI][26])//se naõ tiver marcado ou com erro não envia 
	       _aLog[_nI][01]:=.F.
           _aLog[_nI][30]:="A"
	       If Empty(_aLog[_nI][26])
	          _aLog[_nI][26]:="Não marcado para enviar"//Coluna 26 pq o alog tem um acoluna a mais no inicio 
	       EndIf
           If _lSchedule
		      U_ITCONOUT('Produtor rejeitado por validacao: '+_aLog[_nI][26]+" : "+Str(_nCount,_nTam)+" de "+_cTotal+" - Aceitos: "+Str(_nAceitos,_nTam) )
		   EndIf
	       Loop
	    EndIf
		// Monta a estrutura Do arquivo
		_cXml := U_GLTSQXML( 1 , _cMetodo )
        If _lIntMedVol
	       _cXml += '<listaCamposASeremAlteradosEdicao>codigo</listaCamposASeremAlteradosEdicao>'+CRLF
		EndIf
		_cXml += '<pontoAtendimentos>' +CRLF
		_cXml += '  <codigo>'+ _aDados[_nI][01] +'</codigo>' +CRLF
		_cXml += '  <nome>'+ _aDados[_nI][02]+'</nome>' +CRLF
		_cXml += IIf( !Empty(_aDados[_nI][03]) .And. Val(_aDados[_nI][03]) <> 0 , '  <latitude>'+	_aDados[_nI][03] +'</latitude>'+	CRLF , '' )
		_cXml += IIf( !Empty(_aDados[_nI][04]) .And. Val(_aDados[_nI][04]) <> 0 , '  <longitude>'+	_aDados[_nI][04] +'</longitude>'+	CRLF , '' )
		_cXml += '  <ativo>'+ _aDados[_nI][05] +'</ativo>' +CRLF
		_cXml += IIf( !Empty(_aDados[_nI][06]) , '  <endereco>'+	_aDados[_nI][06] +'</endereco>'+	CRLF , '' )
		_cXml += IIf( !Empty(_aDados[_nI][07]) , '  <bairro>'+ 		_aDados[_nI][07] +'</bairro>'+		CRLF , '' )

		_cXml += '  <customField>' +CRLF
		_cXml += '    <codigo>A2_L_LI_RO</codigo>' +CRLF
		_cXml += '    <valorTexto>'+ _aDados[_nI][20] +'</valorTexto>' +CRLF
		_cXml += '  </customField>' +CRLF
		_cXml += '  <customField>' +CRLF
		_cXml += '    <codigo>VOLUME_MEDIO</codigo>' +CRLF
		_cXml += '    <valorNumerico>'+ AllTrim(Str(_aDados[_nI][28],0)) +'</valorNumerico>' +CRLF
		_cXml += '  </customField>' +CRLF

		_cXml += '  <customField>' +CRLF
		_cXml += '    <codigo>CPF</codigo>' +CRLF//NOVO 14/04/2021
		_cXml += '    <valorTexto>'+ AllTrim(_aDados[_nI][30]) +'</valorTexto>' +CRLF
		_cXml += '  </customField>' +CRLF
		_cXml += '  <customField>' +CRLF
		_cXml += '    <codigo>NIRF</codigo>' +CRLF//NOVO 14/04/2021
		_cXml += '    <valorTexto>'+ AllTrim(_aDados[_nI][31]) +'</valorTexto>' +CRLF
		_cXml += '  </customField>' +CRLF
		_cXml += '  <customField>' +CRLF
		_cXml += '    <codigo>SIG_SIF</codigo>' +CRLF//NOVO 14/04/2021
		_cXml += '    <valorTexto>'+ AllTrim(_aDados[_nI][32]) +'</valorTexto>' +CRLF
		_cXml += '  </customField>' +CRLF
		_cXml += '  <customField>' +CRLF
		_cXml += '    <codigo>NOME_SECUNDARIO</codigo>' +CRLF//NOVO 04/08/2021
		_cXml += '    <valorTexto>'+ AllTrim(_aDados[_nI][33]) +'</valorTexto>' +CRLF
		_cXml += '  </customField>' +CRLF

		_cXml += '  <cidade>' +CRLF
		_cXml += '    <codigo>'+ _aDados[_nI][08] +'</codigo>'+ CRLF
		_cXml += '    <nome>'+ AllTrim(_aDados[_nI][09]) +'</nome>'+ CRLF
		_cXml += '    <estado>'+ CRLF
		_cXml += '      <nome>'+ _aDados[_nI][10] +'</nome>'+ CRLF
		_cXml += '      <sigla>'+ _aDados[_nI][11] +'</sigla>'+ CRLF
		_cXml += '    </estado>'+ CRLF
		_cXml += '  </cidade>'+ CRLF
		_cXml += IIf( !Empty(_aDados[_nI][12]) , '  <email>'+ _aDados[_nI][12] +'</email>'+ CRLF , '' )
		_cXml += IIf( !Empty(_aDados[_nI][13]) , '  <telefone>'+ _aDados[_nI][13] +'</telefone>'+ CRLF , '' )
		_cXml += IIf( !Empty(_aDados[_nI][14]) , '  <tipoPontoAtendimento>'+ CRLF , '' )
		_cXml += IIf( !Empty(_aDados[_nI][14]) , '    <codigo>'+ _aDados[_nI][14] +'</codigo>'+ CRLF , '' )
		_cXml += IIf( !Empty(_aDados[_nI][14]) , '  </tipoPontoAtendimento>'+ CRLF , '' )
		_cXml += '  <unidadeAtendimento>' +CRLF
		_cXml += '    <codigo>'+ _aDados[_nI][15] +'</codigo>' +CRLF
		_cXml += '    <nome>'+ _aDados[_nI][16] +'</nome>' +CRLF

		_cXml += '  </unidadeAtendimento>' +CRLF
		If !Empty(_aDados[_nI][22]) .And. Left(_aDados[_nI][21],1) $ "2,4" .And. _nOpcao # 5//Só envia o pai se For usuario de tanque e Familiar
  		   _cXml += '  <pontoAtendimentoPai>' +CRLF
  		   _cXml += '     <codigo>'+ AllTrim(_aDados[_nI][22]) +'</codigo>' +CRLF
  		   _cXml += '  </pontoAtendimentoPai>' +CRLF
		EndIf
	    _cXml += '</pontoAtendimentos>' +CRLF
		_cXml += U_GLTSQXML( 2 , _cMetodo )

        _cXml := StrTran(_cXml,"v9",_cVerAtual)//AWF-08/03/17 - O envio Do tanque (Pai) só esta na versao 13+ - troco aqui tb por garantia
        _cXml := StrTran(_cXml,"V9",Upper(_cVerAtual))//AWF-08/03/17 - O envio Do tanque (Pai) só esta na versao 13+ - troco aqui tb por garantia

		_cErro:=""
        
        If !_lSchedule//Grava LOG
		   _cFile 	 := "\data\Logs_Generico\"+'MGLT001_'+_aDados[_nI][01]+"_"+(DToS(DATE())+"_"+StrTran(Time(),":",""))+".xml" 
		   _nHdlLog := FCreate(_cFile)
		   FWrite( _nHdlLog , _cXml )
		   FClose( _nHdlLog )
		EndIf//Grava LOG
		
		U_GLTSQENV( _cWS , _cXml ,  , @_cErro , _cMetodo , @_cXmlRet )
		
		If !Empty(_cErro)
			
            _aLog[_nI][01]:=.F.
            _aLog[_nI][30]:="A"
            _aLog[_nI][26]:="-Recusado: "+AllTrim(_cErro)//Coluna 26 pq o alog tem um acoluna a mais no inicio
            If "FAULT OCCURRED While PROCESSING" $  Upper(AllTrim(_cErro))
               _aLog[_nI][26]+=CRLF+"-Solução: No Cad. de Ponto de Antendimento Do SMARTQUESTION procure o Cod. Do Produtor ["+_aDados[_nI][1]+"], VERIFIQUE se tem Ponto Filho com Ponto Filho, se SIM acerte corretamente."
            ElseIf "NAO FOI POSSIVEL ENCONTRAR O PONTO PAI COM CODIGO" $ Upper(AllTrim(_cErro))
               _aLog[_nI][26]+=CRLF+"-Solução: Acesse o Cad. Do Produtor Tanque ["+_aDados[_nI][22]+"] clique em ALTERAR e depois em CONFIRME para ele ser enviado para o Smartquestion tambem."
            Else
               _aLog[_nI][26]+=CRLF+"-Solução: Entre em contato com a Area de TI para verificar esse erro."
            EndIf

            If _lSchedule
			   U_ITCONOUT( 'Produtor ['+_aDados[_nI][01]+'] rejeitado pelo SQ: '+_cErro+" : "+Str(_nCount,_nTam)+" de "+_cTotal+" - Aceitos: "+Str(_nAceitos,_nTam) )
            Else 
			EndIf

			// Tratativa para gravação Do LOG de Erro das Integrações
            If (_nOpcao = 2 .Or. _nOpcao = 5) .And. totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
			   aAdd( _aDadLog , {	'A2_L_SMQST' , SubStr( 'Falha na integração: '+ _cErro , 1 , TamSX3('Z07_CONALT')[01] ) , '' } )
			   U_ITGrvLog( _aDadLog , 'SA2' , 1 , xFilial('SA2') + _aDados[_nI][01] , 'A' , _cCodUsr , Date() , Time() )
			EndIf

            If _lSchedule
  		 	   U_ITCONOUT( 'Produtor ['+_aDados[_nI][01]+'] '+_aLog[_nI][26] )
  			EndIf			
			
		Else
			_nAceitos++
            _aLog[_nI][01]:=.T.
            _aLog[_nI][30]:="B"
            _aLog[_nI][26]:="Aceito: "+_cXmlRet//Coluna 26 pq o alog tem um acoluna a mais no inicio 

			If !_lIntMedVol .And. SA2->( DBSeek( xFilial('SA2') + _aDados[_nI][01] ) ) .And. SA2->A2_L_SMQST == 'P'
                If totvs.framework.environment.Type.get() == '1' .And. (_nOpcao = 2 .Or. _nOpcao = 5)//1-Produção, 2-Homologação,3-Desenvolvimento
				   SA2->(RecLock( 'SA2' , .F. ))
			       SA2->A2_L_SMQST := ' '
				   SA2->( MSUnLock() )
			    EndIf
			EndIf
			
		EndIf
	
	Next _nI

End Sequence

_cTitAux:='Log de Envio - Integração SQ '+_cVerAtual+' - '+If(_nOpcao = 1,"Enviado Teste","Enviado Oficial")+" - Aceitos: "+AllTrim(Str(_nAceitos))

If Len(_aLog) > 0
   aSort(_aLog,,,{ |X,Y| X[30] < Y[30] })
EndIf

If !_lSchedule

   If Len(_aLog) = 0
      MsgAlert("Não foram processados registros.","MGLT00103")
      Return .T.
   EndIf

   _aButtons:={}
   aAdd( _aButtons , { "Envia Email"	, {|| FWMsgRun(,{ |_oProc| MGLT001EML("",_aLog,.T.,_oProc) },'Filtrando dados...',"Aguarde...")   }, "Envia Email Do Log","Envia Email"} )
   aCab:={"","Cod. Produtor","Nome Produtor","Latitude","Longitude","Ativo","Endereco","Bairro","Código município","Nome município",;
          "Nome Estado","Sigla Estado","E-mail","Telefone","Tipo Ponto","Código Setor","Descrição Setor","Código Linha/Rota",;
		  "Código Empresa","Nome Empresa","Descrição Setor","Tipo","Cod. Tanque","Cod. Produtor","Comparação","Resultado da Integração",;
		  "Indice","Setor","Media de Volume","Sit","CPF","NIRF","SIG_SIF","Nome Secundario"}
   _cTit1Aux:=" - Parametro: LT_WSS_END = "+_cWS
         //ITListBox(_cTitAux , _aHeader, _aCols ,_lMaxSiz,_nTipo,_cMsgTop , _lSelUnc , _aSizes , _nCampo ) 
   lRet:=U_ITListBox(_cTitAux , aCab    , _aLog  , .T.    , 4    ,_cTitAux+_cTit1Aux ,          ,         ,        ,,, _aButtons)
   If !lRet
      Return .F.
   EndIf    

Else

   MGLT001EML( "",_aLog,.F. )
   
EndIf

U_ITCONOUT( _cTitAux )

Return .T.

/*
===============================================================================================================================
Programa----------: MGLT001EML
Autor-------------: Alex Wallauer
Data da Criacao---: 17/04/2017
Descrição---------: Rotina para enviar e-mail de notificação quando houver uma falha de integração
Parametros--------: _cObs: Observacoes
                    _aLog: Lista de logs
                    _lProcessa: .T. com Tela
Retorno-----------: .T. e .F.
===============================================================================================================================
*/
Static Function MGLT001EML(  _cObs,_aLog,_lProcessa,_oProc )

Local _aConfig	:= U_ITCFGEML('')
Local _cMsgEml	:= '',_nI
Local _cEmail	:= SuperGetMV("LT_EMLIPSQ",.F.,"sistema@italac.com.br")
Local _cData	:= DToC(DATE())
Local _cHoraT   := _cTimeInicial
Local _cAssunto := 'Wokflow da Integração com o SmartQuestion [Cadastro de Produtores]'
Default _lProcessa:=.F.

If _lProcessa
   _cEmail :=AllTrim(UsrRetMail(RetCodUsr()))+";andre.carvalho@italac.com.br"
   If Empty(_cEmail)
	  MsgStop("Usuário sem e-mail no cadastro","MGLT00104")
      Return .F.
   EndIf
Else
   If Empty(_cEmail)
	  U_ITCONOUT('Sem e-mail cadastrado, verifique o parametro "LT_EML_SMQ" com a area de TI')
      Return .F.
   EndIf
  _cAssunto += " - Processamento agendado (Schedule)"// - Filial : "+cFilAnt+" - "+AllTrim( Posicione('SM0',1,cEmpAnt+cFilAnt,'M0_FILIAL') )

  _cEmail+=";alexandro.ferreira@italac.com.br;andre.carvalho@italac.com.br"

EndIf

U_ITCONOUT("Enviando e-mail de LOG: "+AllTrim(Str(Len( _aLog )))+" registros para: "+_cEmail )

_cMsgEml := '<html>'
_cMsgEml += '<head><title>Integração Do Cadastro de Produtores</title></head>'
_cMsgEml += '<body>'
_cMsgEml += '<style Type="text/css"><!--'
_cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
_cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
_cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-Left: 15px; background-color: #C6E2FF; }'
_cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-Left: 15px; background-color: #E5E5E5; }'
_cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-Left: 15px; background-color: #FFFFFF; }'
_cMsgEml += 'td.aceito	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-Left: 15px; background-color: #00CC00; }'
_cMsgEml += 'td.recusa  { font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-Left: 15px; background-color: #FF0000; }'
_cMsgEml += '--></style>'
_cMsgEml += '<center>'
_cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="700" height="50"><br>'
_cMsgEml += '<table class="bordasimples" width="700">'
_cMsgEml += '    <tr>'
_cMsgEml += '	<td class="titulos"><center>Log de Processamento</center></td>'
_cMsgEml += '	</tr>'
_cMsgEml += '</table>'
_cMsgEml += '<br>'
_cMsgEml += '<table class="bordasimples" width="700">'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td align="center" colspan="2" class="grupos">Integração Do Cadastro de Produtores</b></td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="20%"><b>Data:</b></td>'
_cMsgEml += '      <td class="itens" align="Left" >'+ _cData +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="20%"><b>Hora:</b></td>'
_cMsgEml += '      <td class="itens" align="Left" >'+ _cHoraT +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="20%"><b>Observação:</b></td>'
_cMsgEml += '      <td class="itens" align="Left" >'+ AllTrim(_cObs)+' #OBS# </td>'
_cMsgEml += '    </tr>'
_cMsgEml += '	<tr>'
_cMsgEml += '      <td class="titulos" align="center" colspan="2"><font color="red">Esta é uma mensagem automática. Por favor não responder!</font></td>'
_cMsgEml += '    </tr>'
_cMsgEml += '</table>'

If _aLog # NIL .And. !Empty(_aLog)  .And. Len( _aLog ) > 0
	_cMsgEml += '<br>'
	_cMsgEml += '<table class="bordasimples" width="1300">'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td align="center" colspan="5" class="grupos">Resultado da Integração Do Cadastro de Produtores</b></td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="center" width="1%"><b>  </b></td>'
	_cMsgEml += '      <td class="itens" align="Left"   width="32%"><b>Codigo / Loja / Produtor</b></td>'
     If !_lIntMedVol
	    _cMsgEml += '  <td class="itens" align="center" width="12%"><b>Setor / Linha</b></td>'
	 Else   
	    _cMsgEml += '  <td class="itens" align="center" width="12%"><b>Media Volume</b></td>'
     EndIf
	_cMsgEml += '      <td class="itens" align="Left"   width="19%"><b>Tipo / Cod. Tanque</b></td>'
	_cMsgEml += '      <td class="itens" align="Left"   width="38%"><b>Resultado da Integracao</b></td>'
	_cMsgEml += '    </tr>'
	If _lProcessa
	    _nCount:=Len( _aLog )
        _cTotal:=AllTrim(Str(_nCount))
        _nTam:=Len(_cTotal)+1  
        _nCount:=0
	EndIf
	_nBloquedos:=0
    _nLiberados:=0
    _nConta    :=0
	For _nI := 1 To Len( _aLog )
	    If _lProcessa
           _nCount++
           _oProc:cCaption := ("Enviando produtor "+_aLog[_nI][02]+" : "+Str(_nCount,_nTam)+" de "+_cTotal )
           ProcessMessages()
	    EndIf
		_cMsgEml += '    <tr>'
		If !_aLog[_nI][1]
			_cMsgEml += '  <td class="recusa" align="center" width="1%"><b>R</b></td>'
		Else
			_cMsgEml += '  <td class="aceito" align="center" width="1%"><b>A</b></td>'
		EndIf
		_cMsgEml += '      <td class="itens" align="Left" width="32%">'+ _aLog[_nI][02]+" / "+_aLog[_nI][03]+'</td>'
        If !_lIntMedVol
		  _cMsgEml += '    <td class="itens" align="Left" width="12%">'+ _aLog[_nI][16]+" / "+_aLog[_nI][21]+'</td>'
		Else  
		  _cMsgEml += '    <td class="itens" align="Left" width="12%">'+TRANS(_aLog[_nI][29],"@E 999,999,999,999,999")+'</td>'
        EndIf
		_cMsgEml += '      <td class="itens" align="Left" width="19%">'+ _aLog[_nI][22]+" / "+_aLog[_nI][23]+" ["+AllTrim(_aLog[_nI][25])+'] </td>'
		_cMsgEml += '      <td class="itens" align="Left" width="38%">'+ _aLog[_nI][26]+'</td>'
		_cMsgEml += '    </tr>'
        
		If !_aLog[_nI][01]
		   _nBloquedos++
		Else
           _nLiberados++
        EndIf
        _nConta++
		
	Next _nI
	
	_cMsgEml += '</table>'
	
EndIf
_cObsT:=""
If _nLiberados # 0
   _cObsT:=AllTrim(Str(_nLiberados,10))+' Produtores Aceitos "A" (Verde) '+CRLF
EndIf
If _nBloquedos # 0
   _cObsT+=AllTrim(Str(_nBloquedos,10))+' Produtores Recusados "R" (Vermelho) '+CRLF
EndIf
_cMsgEml:=StrTran(_cMsgEml,"#OBS#",_cObsT)  

_cMsgEml += '</center>'

_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" ><b>Ambiente / Versao WebSQ / Parametro:</b></td>'
_cMsgEml += '      <td class="itens" align="Left" > '+GetEnvServer()+' / '+_cVerAtual+' / '+_cWS+'</td>'
_cMsgEml += '    </tr>'

_cMsgEml += '</body>'
_cMsgEml += '</html>'

_cEmlLog := ''
//    ITEnvMail(cFrom     ,cEmailTo ,cEmailCo,cEmailBcc,cAssunto ,cMensagem,cAttach   ,cAccount    ,cPassword   ,cServer      ,cPortCon    ,lRelauth     ,cUserAut     ,cPassAut     ,cLogErro)
U_ITENVMAIL( _aConfig[01] , _cEmail ,        ,         ,_cAssunto, _cMsgEml ,         ,_aConfig[01],_aConfig[02], _aConfig[03],_aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )

If !Empty( _cEmlLog )
   If _lProcessa
      U_ITMsg( _cEmlLog+CRLF+" E-mails: "+_cEmail , 'Envio Do WF por e-mail',,1)
   Else
      U_ITCONOUT("Resultado Do envio Do email: "+_cEmlLog+" - E-mail(s): "+_cEmail)
      U_ITCONOUT("Integração com o SmartQuestion Do Cadastro de Produtores - [ "+AllTrim(Str(_nConta,10))+" Produtores Processados ]")
   EndIf
Else
   If _lProcessa
      MsgInfo("Enviado E-mails: "+_cEmail+", "+AllTrim(Str(_nConta,10))+" Produtores Processados ]", "integração SQ [Produtores]  - "+TIME(),"MGLT00105")
   Else
      U_ITCONOUT("Resultado Do envio Do email: "+_cEmlLog+" - E-mail(s): "+_cEmail)
      U_ITCONOUT("Integração com o SmartQuestion [Cadastro de Produtores] - [ "+AllTrim(Str(_nConta,10))+" Produtores Processados ]")
   EndIf
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: MGLT01
Autor-------------: Alex Wallauer
Data da Criacao---: 03/10/2018
Descrição---------: Rotina de Integração via WebService de integração de Média de Volume dos Produtores para o SmartQuestion
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGLT01MV()
Return U_MGLT001(.T.)
