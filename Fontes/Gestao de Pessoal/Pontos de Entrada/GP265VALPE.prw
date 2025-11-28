/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |19/09/2017| Chamado 21467. Troca de numerador do DA4 para getsxexnum
Josué Danich  |18/07/2018| Chamado 25427. Reescrita de cadastro para aproveitar fornecedor/motorista pré existente
Lucas Borges  |02/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "topconn.ch"

/*
===============================================================================================================================
Programa----------: Gp265ValPE
Autor-------------: Tiago Correa Castro
Data da Criacao---: 06/11/2008
Descrição---------: Ponto de Entrada para validar a inclusao/alteracao do cadastro de autonomo
Parametros--------: Nenhum
Retorno-----------: .T. - Permite a Inclusão/Alteração
------------------: .F. - Não permite a Inclusão/Alteração
===============================================================================================================================
*/
User Function Gp265ValPE()

Local _aArea		:= FWGetArea()
Local _lRet			:= .T.
Local _cCPF			:= M->RA_CIC
Local _cSefip		:= M->RA_CATEG
Local _cMatric		:= M->RA_MAT
Local _cAutFret		:= M->RA_I_AUTFR
Local cCodigo		:= "00001"
Local _cAliasSRA	:= GetNextAlias()
Local nCountRec		:= 0

//Log de utilização
U_ITLOGACS()

//Valida filial de cadastro de autonomos
If !(cfilant $ u_itgetmv("ITFILAUT","01"))

	U_ITMsg("Filial " + cfilant + " não autorizada para cadastro de autonomos!","Atenção","Filial(is) autorizada(s) para cadastro de autonomos: " + AllTrim(u_itgetmv("ITFILAUT","01")),1)
	Return .F.

EndIf

//================================================================================
//| Verifico preenchimento dos campos de DDD e número do celular
//================================================================================
If Empty(M->RA_DDDCELU) .Or. Empty(M->RA_NUMCELU)
	U_ITMsg(	 "Preenchimento do campo de DDD e número do celular é obrigatório. Devido a integração com o cadastro de motoristas."	,"Campo Obrigatório.",;
					"Favor preencher o campo de DDD e número do celular.",1				 												)

	Return(.F.)
EndIf


If Len(AllTrim(_cCPF)) > 0

	cQuery := " SELECT RA_MAT "
	cQuery += " FROM " + RetSqlName("SRA")
	If inclui 
		cQuery += " WHERE D_E_L_E_T_ = ' ' AND RA_SITFOLH <> 'D' AND RA_CIC = '"  + _cCPF    + "' AND RA_CATEG = '"  + _cSefip + "' "
	ElseIf altera
		cQuery += " WHERE D_E_L_E_T_ = ' ' AND RA_SITFOLH <> 'D' AND RA_MAT <> '" + _cMatric + "' AND RA_CIC = '"    + _cCPF   + "' "
		cQuery += " AND RA_CATEG = '" + _cSefip + "' "
	EndIf
	
	If Select(_cAliasSRA) > 0
		(_cAliasSRA)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cQuery) , _cAliasSRA , .T. , .F. )
	COUNT TO nCountRec
	
	DBSelectArea(_cAliasSRA)
	(_cAliasSRA)->( DBCloseArea() )
	
	If nCountRec > 0
		
		If Inclui
		
			U_ITMsg("Nao será possível a inclusao desse registro pois ja existe um registro com o mesmo CPF e Categ. SEFIP na base de Dados!!","Cadastro duplicado - Inclusao",;
						"Favor verificar se os dados do Registro estão corretos!!",1)
			_lRet	:=	.F.
			
		ElseIf Altera
		
			U_ITMsg("Nao será possível a alteracao desse registro pois ja existe um registro com o mesmo CPF e Categ. SEFIP com Matricula diferente na base de Dados!!",;
						"Cadastro duplicado - Alteracao",;
						"Favor verificar se os dados do Registro estão corretos!!",1)
			_lRet	:=	.F.
			
		EndIf                                                                          
	
	EndIf                                                                              

Else

	U_ITMsg("Para realizar o cadastro do Autonomo é necessario que se preencha o campo CPF.","Informação",;
				"Favor fornecer o CPF do Autonomo antes de realizar o seu cadastro.",1)
	_lRet	:=	.F.

EndIf
    
If _lRet .And. Inclui .And. _cSefip == "15" .And. _cAutFret == "S"

	cQuery := " SELECT MAX( SubStr(RA_MAT,2,5) ) AS MAXIMO "
	cQuery += " FROM " + RetSqlName("SRA")
	cQuery += " WHERE RA_FILIAL = '01' AND D_E_L_E_T_ = ' ' AND SubStr(RA_MAT,1,1) = '4' "
	
	TcQuery cQuery New Alias "TEMP"
	
	DBSelectArea("TEMP")
	TEMP->( DBGoTop() )
	
    If TEMP->( !Eof() )
    	cCodigo := StrZero( Val(TEMP->MAXIMO) + 1 , 5 )
    EndIf
	
	TEMP->( DBCloseArea() )
	
	cCodigo := "4" + cCodigo
	
	//================================================================================
	//| Verifica se o código está disponível                                         |
	//================================================================================
	While !MayIUseCode( "SRA" + xFilial("SRA") + cCodigo )
		cCodigo := Soma1(cCodigo)
	EndDo
	
	M->RA_MAT := cCodigo

EndIf

//================================================================================
//| Gera cadastros DO MOTORISTA E TRANSPORTADORA para autonomo
//================================================================================
If _lRet

	If M->RA_CATEG == "15" .And. M->RA_I_AUTFR == "S"

		_lRet := OkGeraCad()
		
	EndIf
	
EndIf

FWRestArea( _aArea )
	
Return _lRet                     
                     

/*
===============================================================================================================================
Programa----------: OkGeraCad
Autor-------------: Fabiano Dias
Data da Criacao---: 08/07/2010
Descrição---------: Geração automática do cadastro de Fornecedor e Motorista a partir do Autônomo
Parametros--------: Nenhum
Retorno-----------: lret - se conseguiu gerar o cadastro com sucesso
===============================================================================================================================
*/
Static Function OkGeraCad()  

Local _lRet		:= .T.
Local aVetor 	:= {}
Local _cFilial	:= xFilial("SRA")
Local _cCodForn	:= ""
Local _cLojForn	:= "0001"
Local _cCodAuto := M->RA_MAT
Local _cNome 	:= AllTrim( M->RA_NOMECMP	)
Local _cNReduz	:= AllTrim( M->RA_NOME		)
Local _cEnd 	:= AllTrim( M->RA_ENDEREC	)
Local _cBairro 	:= AllTrim( M->RA_BAIRRO	)
Local _cMuni	:= AllTrim( M->RA_MUNICIP	)
Local _cEst 	:= M->RA_ESTADO
Local _cCodMuni := M->RA_CODMUN
Local _cCEP 	:= M->RA_CEP
Local _cTipo 	:= "F"
Local _cCPF 	:= M->RA_CIC
Local _cOrgRG	:= M->RA_RGORG
Local _cInscEst := "" // "ISENTO"
Local _cDDD		:= M->RA_DDDFONE
Local _cTel 	:= AllTrim( M->RA_TELEFON )
Local _cTelComp	:= M->RA_TELEFON
Local _cCNH		:= M->RA_HABILIT
Local _cPai		:= AllTrim( M->RA_PAI )
Local _cMae		:= AllTrim( M->RA_MAE )
Local _cCodMot	:= ""
Local _cRg		:= AllTrim( M->RA_RG ) 
Local _cEmail	:= AllTrim( M->RA_EMAIL )
Local _cDDDCel	:= M->RA_DDDCELU
Local _cCelula	:= AllTrim( M->RA_NUMCELU )

Private lMsErroAuto := .F.
				
Begin Transaction				

	//================================================================================
	//| Cadastro de fornecedor                                                       |
	//================================================================================
	
	//Identifica se já existe fornecedor tipo autonomo com mesmo cpf
	_lachou := .F.
	SA2->(DBSetOrder(3))
	If SA2->(DBSeek(xFilial("SA2")+AllTrim(_cCPF)))
	
		While SA2->A2_FILIAL == xFilial("SA2") .And. AllTrim(SA2->A2_CGC) ==  AllTrim(_cCPF)
		
		  If AllTrim(SA2->A2_I_CLASS) == "A"
		  
		  	_cCodForn := AllTrim(SA2->A2_COD)
		  	_lachou := .T.
		  	
		  EndIf
		  
		  SA2->(DBSkip())
		  
		EndDo
		
		If Empty(_cCodForn)
		
			_cCodForn := U_ACOM005( "A" , _cTipo , _cCPF )
			
		EndIf
		
	Else
	
		_cCodForn := U_ACOM005( "A" , _cTipo , _cCPF )
	
	EndIf
	
	aAdd( aVetor , {	"A2_I_CLASS"	, "A"												, nil } )
	aAdd( aVetor , {	"A2_TIPO"		, _cTipo										 	, nil } )
	aAdd( aVetor , {	"A2_CGC"		, _cCPF												, nil } )
	aAdd( aVetor , {	"A2_COD"		, _cCodForn											, nil } )
	aAdd( aVetor , {	"A2_LOJA"		, _cLojForn											, nil } )
	aAdd( aVetor , {	"A2_NOME"		, PadR( _cNome		, TamSX3('A2_NOME')[01]		)	, nil } ) 
	aAdd( aVetor , {	"A2_NREDUZ"		, PadR( _cNReduz	, TamSX3('A2_NREDUZ')[01]	)	, nil } ) 
	aAdd( aVetor , {	"A2_EST"		, _cEst												, nil } )
	aAdd( aVetor , {	"A2_COD_MUN"	, _cCodMuni											, nil } )
	aAdd( aVetor , {	"A2_MUN"		, _cMuni											, nil } )
	aAdd( aVetor , {	"A2_CEP"		, _cCEP												, nil } )
	aAdd( aVetor , {	"A2_END"		, _cEnd												, nil } )
	aAdd( aVetor , {	"A2_BAIRRO"		, _cBairro											, nil } )
	aAdd( aVetor , {	"A2_INSCR" 		, _cInscEst											, nil } )
	aAdd( aVetor , {	"A2_DDD"		, _cDDD												, nil } )
	aAdd( aVetor , {	"A2_TEL"		, _cTel 											, nil } )
	If !Empty( _cEmail )
	aAdd( aVetor , {	"A2_EMAIL"		, _cEmail											, nil } )
	EndIf
	aAdd( aVetor , {	"A2_I_FLAUT"	, _cFilial										 	, nil } )
	aAdd( aVetor , {	"A2_I_AUT"		, _cCodAuto											, nil } )
	
	MSExecAuto( {|x,y| Mata020(x,y) } , aVetor , IIf(_lachou,4,3) )
	
	If lMSErroAuto
	
		DisarmTransaction()
		
		If ( __lSx8 )
			RollBackSx8()
		EndIf 
		
		Mostraerro()
		_lRet:= .F.    
		
	Else        
	
		dbCommit()
		
		If ( __lSX8 )
			ConfirmSX8()
		EndIf				
		
	EndIf
    
    //================================================================================
	//| Cadastro de motorista                                                        |
	//================================================================================
	lMsErroAuto := .F.
	aVetor 		:= 	{}  
	_lachou := .F.

	DA4->(DBSetOrder(3))
	If DA4->(DBSeek(xFilial("DA4")+AllTrim(_cCPF)))
	
		_cCodMot := DA4->DA4_COD
		_lachou := .T.
		aVetor := { { 'DA4_NOME'	, PadR( _cNome		, TamSX3('DA4_NOME')[01]	)	, nil },; 
				{ 'DA4_NREDUZ'	, PadR( _cNReduz	, TamSX3('DA4_NREDUZ')[01]	)	, nil },; 
				{ 'DA4_FORNEC'	, _cCodForn											, NIL },;
				{ 'DA4_LOJA'	, _cLojForn											, NIL },;
				{ 'DA4_EST'		, _cEst												, NIL },;
				{ 'DA4_I_CMUN'	, _cCodMuni											, NIL },;
				{ 'DA4_MUN'		, _cMuni											, NIL },;
				{ 'DA4_CEP'		, _cCEP												, NIL },;
				{ 'DA4_END'		, _cEnd												, NIL },;
				{ 'DA4_BAIRRO'	, _cBairro											, NIL },;
				{ 'DA4_I_DDD2'	, StrZero(Val(_cDDD),3,0)							, nil },;
				{ 'DA4_TELREC'	, _cTelComp											, nil },;
				{ 'DA4_DDD'		, StrZero(Val(_cDDDCel),3,0)						, nil },;
				{ 'DA4_TEL'		, _cCelula											, nil },;
				{ 'DA4_CGC'		, _cCPF												, NIL },;
				{ 'DA4_NUMCNH'	, _cCNH												, NIL },;
				{ 'DA4_PAI'		, _cPai												, NIL },;
				{ 'DA4_MAE'		, _cMae												, NIL },;
				{ 'DA4_RGORG'	, _cOrgRg											, NIL },; 
				{ 'DA4_RG'		, _cRg												, NIL } } 
		
		
	Else
	
		_cCodMot := GETSXENUM("DA4","DA4_COD")
		aVetor := { { 'DA4_COD'		, _cCodMot											, NIL },;
				{ 'DA4_NOME'	, PadR( _cNome		, TamSX3('DA4_NOME')[01]	)	, nil },; 
				{ 'DA4_NREDUZ'	, PadR( _cNReduz	, TamSX3('DA4_NREDUZ')[01]	)	, nil },; 
				{ 'DA4_FORNEC'	, _cCodForn											, NIL },;
				{ 'DA4_LOJA'	, _cLojForn											, NIL },;
				{ 'DA4_EST'		, _cEst												, NIL },;
				{ 'DA4_I_CMUN'	, _cCodMuni											, NIL },;
				{ 'DA4_MUN'		, _cMuni											, NIL },;
				{ 'DA4_CEP'		, _cCEP												, NIL },;
				{ 'DA4_END'		, _cEnd												, NIL },;
				{ 'DA4_BAIRRO'	, _cBairro											, NIL },;
				{ 'DA4_I_DDD2'	, StrZero(Val(_cDDD),3,0)							, nil },;
				{ 'DA4_TELREC'	, _cTelComp											, nil },;
				{ 'DA4_DDD'		, StrZero(Val(_cDDDCel),3,0)						, nil },;
				{ 'DA4_TEL'		, _cCelula											, nil },;
				{ 'DA4_CGC'		, _cCPF												, NIL },;
				{ 'DA4_NUMCNH'	, _cCNH												, NIL },;
				{ 'DA4_PAI'		, _cPai												, NIL },;
				{ 'DA4_MAE'		, _cMae												, NIL },;
				{ 'DA4_RGORG'	, _cOrgRg											, NIL },; 
				{ 'DA4_RG'		, _cRg												, NIL } } 
		
		
	EndIf
	

	//================================================================================
	//| Rotina de ExecAuto usando MVC                                                | 
	//================================================================================
	lMSErroAuto := !ITExecAutoDA4( aVetor , IIf(_lachou,4,3) )
	
	If lMSErroAuto
	
		DisarmTransaction()
		
		If ( __lSx8 )
			RollBackSx8()
		EndIf 
		
		_lRet := .F.     
		
	Else
	
		DBCommit()
		
		If ( __lSX8 )
			ConfirmSX8()
		EndIf
		
	EndIf

End Transaction

Return( _lRet )

/*
===============================================================================================================================
Programa----------: ITExecAutoDA4
Autor-------------: Alexandre Villar
Data da Criacao---: 30/07/2014
Descrição---------: Processamento do ExecAuto via MVC de acordo com a rotina padrão
Parametros--------: _avetor - array com campos e dados para o execauto
					_noper - operação do execauto
Retorno-----------: lret - se conseguiu executar o execauto com sucesso
===============================================================================================================================
*/
Static Function ITExecAutoDA4( _aVetor , _nOper )

Local _oModel	:= Nil
Local _oAux		:= Nil
Local _oStruct	:= Nil
Local _nI		:= 0
Local _nPos		:= 0
Local _lRet		:= .T.
Local _aAux		:= {}
Local _aErro	:= {}

DBSelectArea( 'DA4' )
DA4->( DBSetOrder( 1 ) )

//================================================================================
//| Instancia o objeto com o modelo de dados da Rotina                           |
//================================================================================
_oModel := FWLoadModel( 'OMSA040' )

//================================================================================
//| Define a operação: 3 – Inclusão / 4 – Alteração / 5 - Exclusão               |
//================================================================================
_oModel:SetOperation( _nOper )

//================================================================================
//| Ativação do Modelo de Dados                                                  |
//================================================================================
_oModel:Activate()

//================================================================================
//| Instancia o Modelo de Dados                                                  |
//================================================================================
_oAux := _oModel:GetModel( 'OMSA040_DA4' )

//================================================================================
//| Obtém a estrutura de Dados e Campos                                          |
//================================================================================
_oStruct	:= _oAux:GetStruct()
_aAux		:= _oStruct:GetFields()

For _nI := 1 To Len( _aVetor )
	
	//================================================================================
	//| Verifica se os campos passados existem na estrutura do modelo                |
	//================================================================================
	If ( _nPos := aScan( _aAux , {|x| AllTrim( x[03] ) == AllTrim( _aVetor[_nI][01] ) } ) ) > 0
		
		//================================================================================
		//| Atribui conteúdo ao campo do Model                                           |
		//================================================================================
		If !( _oModel:SetValue( 'OMSA040_DA4' , _aVetor[_nI][01] , _aVetor[_nI][02] ) )
			
			_lRet := .F.
			Exit
			
		EndIf
		
	EndIf
	
Next _nI

If _lRet

	//================================================================================
	//| Caso tenha feito a atribuição dos dados, chama a validação da rotina         |
	//================================================================================
	If ( _lRet := _oModel:VldData() )
		_oModel:CommitData()
	EndIf
	
EndIf

If !_lRet
	
	//================================================================================
	//| Exibe o LOG da rotina em caso de erros                                       |
	//================================================================================
	_aErro := _oModel:GetErrorMessage()
	
	AutoGrLog( "Id do formulário de origem..: " + ' [' + AllToChar( _aErro[1] ) + ']' )
	AutoGrLog( "Id do campo de origem.......: " + ' [' + AllToChar( _aErro[2] ) + ']' )
	AutoGrLog( "Id do formulário de erro....: " + ' [' + AllToChar( _aErro[3] ) + ']' )
	AutoGrLog( "Id do campo de erro.........: " + ' [' + AllToChar( _aErro[4] ) + ']' )
	AutoGrLog( "Id do erro..................: " + ' [' + AllToChar( _aErro[5] ) + ']' )
	AutoGrLog( "Mensagem do erro............: " + ' [' + AllToChar( _aErro[6] ) + ']' )
	AutoGrLog( "Mensagem da solução.........: " + ' [' + AllToChar( _aErro[7] ) + ']' )
	AutoGrLog( "Valor atribuído.............: " + ' [' + AllToChar( _aErro[8] ) + ']' )
	AutoGrLog( "Valor anterior..............: " + ' [' + AllToChar( _aErro[9] ) + ']' )
	
	MostraErro()
	
EndIf

_oModel:DeActivate()

Return( _lRet )
