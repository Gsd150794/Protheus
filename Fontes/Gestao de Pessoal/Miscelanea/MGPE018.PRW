/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |15/03/2019| Chamado 28466. Ajuste para retirada do PE M020INC
Josué Danich  |29/03/2019| Chamado 28661. Correção de campo município na gravação de SA2.
Lucas Borges  |26/06/2019| Chamado 28346. Revisão de fontes.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MGPE018
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 09/06/2017
===============================================================================================================================
Descrição---------: Função principal que chama função que transforma o funcionário em fornecedor
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE018()

If MsgYesNo("Deseja realmente fazer a geração os funcionários para clientes?","MGPE01801")
	FWMsgRun( ,{|| MGPE018G() }, , "Aguarde, processando informações de funcionários para criação dos Fornecedores...")
EndIf

Return

/*
===============================================================================================================================
Programa----------: MGPE018G
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 09/06/2017
Descrição---------: Função que faz a leitura dos funcionários para criação de Fornecedor
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE018G()

DBSelectArea("SRA")
SRA->(DBGoTop())

While !SRA->(Eof())
	If SRA->RA_SITFOLH <> 'D' .And. SRA->RA_CATFUNC == 'M'
		//================================================================================
		// VERIFICA SE O FUNCIONARIO JA POSSUI CADASTRO REALIZADO NO CADASTRO DE CLIENTES
		//================================================================================
		_aCadFornec := MGPE018V( SRA->RA_CIC )
	
		If _aCadFornec[1,1]
	
			//================================================================================
			// RECUPERA OS DADOS DO FUNCIONÁRIO PARA INCLUSÃO DO CLINTE
			//================================================================================
			_aFornec := FWMsgRun( ,{|| MGPE018D( 1 , "" , "" ) }, , "Gerando Fornecedor para o funcionário: " + SRA->RA_MAT + " - " + AllTrim(SRA->RA_NOME) + "...")
		EndIf
	EndIf
	SRA->(DBSkip())
End                                          				

Return

/*
===============================================================================================================================
Programa----------: MGPE018V
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 09/06/2017
Descrição---------: Função que valida se já existe cadastro de cliente para o funcionário que está sendo inserido/alterado
Parametros--------: _cCpf - Cpf do funcionário
Retorno-----------: _aRet - Retorna os dados referentes ao cadastro, ou indicação de que o mesmo não existe
===============================================================================================================================
*/
Static Function MGPE018V( _cCPF )

Local _nCntRec		:= 0
Local _cAliasSA2	:= GetNextAlias()          
Local _aRet			:= {}

BeginSql alias _cAliasSA2
	SELECT SA2.A2_COD, SA2.A2_LOJA
	  FROM %Table:SA2% SA2
	 WHERE SA2.D_E_L_E_T_ = ' '
	   AND SA2.A2_Filial = %xFilial:SA2%
	   AND SA2.A2_MSBLQL <> '1'
	   AND SA2.A2_CGC = %exp:_cCPF%
EndSql
	
Count To _nCntRec
(_cAliasSA2)->( DBGoTop() )

If _nCntRec > 0
	aAdd( _aRet , { .F. , (_cAliasSA2)->A2_COD	, (_cAliasSA2)->A2_LOJA	})
Else
 	aAdd( _aRet , { .T. , ""					, ""					})
EndIf

(_cAliasSA2)->( DBCloseArea() )

Return( _aRet )

/*
===============================================================================================================================
Programa----------: MGPE018D
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 09/06/2017
Descrição---------: Função que insere os dados da importação dos funcionários para o cadastro de clientes de acordo com a
------------------: operação (inclusão/alteração)
Parametros--------: _cTipo   = 1 - Inclusão / 2 - Alteração
------------------: _cCodCli = Código do Cliente
------------------: _cLojCLi = Loja do Cliente
Retorno-----------: _aCliente - Retorna os dados referentes ao cadastro
===============================================================================================================================
*/
Static Function MGPE018D( _cTipo , _cCodFor , _cLojaFor )

Local _aFornec		:= {}
Local avetor        := {}

Private lMSErroAuto := .F.

Default _cCodFor	:= U_ACOM005("J", "F", SRA->RA_CIC)
Default _cLojaFor	:= "0001"

If Empty(_cCodFor)
	_cCodFor	:= U_ACOM005("J", "F", SRA->RA_CIC)
EndIf

If Empty(_cLojaFor)
	_cLojaFor	:= "0001"
EndIf

//Monta array do execauto
aVetor := {}
aAdd( aVetor , {	"A2_I_CLASS"	, "J"												, nil } )
aAdd( aVetor , {	"A2_TIPO"		, "F"											 	, nil } )
aAdd( aVetor , {	"A2_CGC"		, SRA->RA_CIC											, nil } )
aAdd( aVetor , {	"A2_COD"		, _cCodFor											, nil } )
aAdd( aVetor , {	"A2_LOJA"		, _cLojaFor											, nil } )
aAdd( aVetor , {	"A2_NOME"		, AllTrim(SRA->RA_NOME)								, nil } ) 
aAdd( aVetor , {	"A2_NREDUZ"		, AllTrim(SRA->RA_NOME)								, nil } ) 
aAdd( aVetor , {	"A2_EST"		, AllTrim(SRA->RA_ESTADO)								, nil } )
aAdd( aVetor , {	"A2_COD_MUN"	, AllTrim(SRA->RA_CODMUN)								, nil } )
aAdd( aVetor , {	"A2_MUN"	     ,AllTrim(Posicione('CC2',1,xFilial('CC2')+M->RA_ESTADO+M->RA_CODMUN,'CC2_MUN'))   , nil } )
aAdd( aVetor , {	"A2_CEP"		, AllTrim(SRA->RA_CEP)								, nil } )
aAdd( aVetor , {	"A2_END"		, AllTrim(SRA->RA_ENDEREC)+", "+AllTrim(M->RA_LOGRNUM), nil } )
aAdd( aVetor , {	"A2_BAIRRO"		, AllTrim(SRA->RA_BAIRRO)								, nil } )
aAdd( aVetor , {	"A2_DDD"		, AllTrim(SRA->RA_DDDFONE)							, nil } )
aAdd( aVetor , {	"A2_TEL"		, AllTrim(SRA->RA_TELEFON)							, nil } )
If !Empty( AllTrim(M->RA_EMAIL) )
	aAdd( aVetor , {	"A2_EMAIL"		,AllTrim(SRA->RA_EMAIL)								, nil } )
EndIf
aAdd( aVetor , {	"A2_BANCO"		, SubStr(SRA->RA_BCDEPSA,1,3)							, nil } )
aAdd( aVetor , {	"A2_AGENCIA"	, SubStr(SRA->RA_BCDEPSA,4,5)							, nil } )
aAdd( aVetor , {	"A2_NUMCON"		, SubStr(SRA->RA_CTDEPSA,1,10)						, nil } )
aAdd( aVetor , {	"A2_PAIS"		, '105'		 										, nil } )
aAdd( aVetor , {	"A2_CODPAIS"	, '01058'	 										, nil } )
aAdd( aVetor , {	"A2_TRIBFAV"	, '2'	 											, nil } )

MSExecAuto( {|x,y| Mata020(x,y) } , aVetor , IIf(_ctipo==2,4,3) )
	
If lMSErroAuto
	If ( __lSx8 )
		RollBackSx8()
	EndIf 
	mostraerro()
Else        
	dbCommit()
	If ( __lSX8 )
		ConfirmSX8()
	EndIf				
EndIf

RecLock("SRA",.F.)
	SRA->RA_I_F := _cCodFor
MSUnLock()

FreeUsedCode()

Return( _aFornec )
