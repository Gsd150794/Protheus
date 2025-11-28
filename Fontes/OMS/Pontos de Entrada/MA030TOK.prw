/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
 Josué Danich     | 27/07/2017 | Chamado: 20916 - Validar campos de pallet chep, revisão para 12.
 Josué Danich     | 13/06/2019 | Chamado: 29648 - Não valida isento/email na importação de funcionário.
 Lucas Borges     | 11/10/2019 | Chamado: 28346 - Removidos os Warning na compilação da release 12.1.25. 
 Julio Paz        | 12/03/2021 | Chamado: 35759 - Quando Cliente alterado p/Simples Nacional=Não,limpar codigo tab Treço Simp.Nac.
 Igor Melgaço     | 04/05/2021 | Chamado: 36378 - Quando grupo de cliente é genérico o vendedor tb tem que ser genérico.
 Julio Paz        | 20/12/2021 | Chamado: 25540 - Desenv.Rotina Env.WorkFlow quando vendedor1,2,3,4 For alter.e Grupo Env.WorkFlow.
 Julio Paz        | 23/12/2021 | Chamado: 30177 - Alterações diversas relacionados a Desconto Contratual. 
 Igor Melgaço     | 30/05/2022 | Chamado: 40048 - Ajustes para validação de caracteres inválidos. 
 Igor Melgaço     | 11/08/2022 | Chamado: 40048 - Ajustes para conversão de caracteres.
 Julio Paz        | 24/05/2023 | Chamado: 43808 - Ajustar layout/validações execauto p/Importação Clientes Broker p/novo layout  
 Julio Paz        | 07/07/2023 | Chamado: 44399 - Correções nas validações de cadastro clientes criados na efetivação prospect
 Julio Paz        | 25/07/2023 | Chamado: 44096 - Ajustar rotina incl/alter gravar Grupo Tributação "023" p/Parana e Simples Nac
 Igor Melgaço     | 02/07/2024 | Chamado: 47127 - Ajustes para não gravar o campo A1_MSBLQL.
 Igor Melgaço     | 12/07/2024 | Chamado: 47556 - Ajuste para preenchimento obrigatório do campo A1_CNAE.
 Igor Melgaço     | 16/07/2024 | Chamado: 48523 - Ajuste para exceção do fonte MOMS003.
===============================================================================================================================
Analista - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
===================================================================================================================================================================================================
Antonio  - Julio Paz     - 17/06/25 - 27/06/25 - 50278   - Criação de Campo e Inclusão de validações para determinar usuários que podem incluir/alterar Clientes com base nos limetes de crédito.
Antonio  - Julio Paz     - 01/07/25 - 01/07/25 - 51203   - Ajustar as validações por limite de crédito para não validar quando For MSEXECAUTO dos fontes: GP010VALPE/GPE10MENU/MOMS003/MOMS055. 
Antonio  - Igor Melgaço  - 11/09/25 -          - 51346   - Ajuste para replicar A1_COND e A1_GRPVEN entre clientes com mesma base de CNPJ.
===================================================================================================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "RwMake.ch"
#Include "TopConn.ch" 
#Include "TOTVS.ch"
#Include 'fileio.ch'

#define CRLF		Chr(13) + Chr(10)

Static _aBloqSA1 := {}  // Array Static para guardar informações de bloqueio por desconto contratual.

/*
===============================================================================================================================
Programa----------: MA030TOK
Autor-------------: Talita Teixeira
Data da Criacao---: 27/03/2013
===============================================================================================================================
Descrição---------: Validações no cadastro de Clientes
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Lógico com exibição de mensagens para tratativa das negativas
===============================================================================================================================
*/
User Function MA030TOK()

Local _aArea	:= FWGetArea()
Local _cAlias	:= GetNextAlias()
Local _cQuery	:= ""
Local _cUser	:= ""
Local _cCodigo	:= ""
Local _cTxtAux	:= ""
Local _lRet		:= .T.
Local _lMashup	:= U_ItGetMV("IT_MASHUP",.F.)
Local _lLibMas	:= .F.
Local _nQtdDia	:= Val(M->A1_I_PEREX)
Local _nQtdiaT	:= IIf(Empty(M->A1_I_DTEXE),0,dDataBase - M->A1_I_DTEXE)
Local _lExec	:= IIf(_nQtdiaT > _nQtdDia, .T., .F.)
Local _cVendGen := U_ITGetMV("IT_VENDGEN","000156")
Local _cGrpGen  := U_ITGetMV("IT_GRPGEN","11")
Local _cEnvWorkF  := "S"
Local _aListaVend := {}
Local _cNomeGrupo := ""
Local _cNomVendA := ""
Local _cNomVendB := ""
Local _cDescCont := ""
Local _cA1_NOME    := ""
Local _cA1_END     := ""
Local _cA1_BAIRRO  := ""
Local _cA1_ENDCOB  := ""
Local _cA1_ENDREC  := ""
Local _cA1_ENDENT  := ""
Local _cA1_BAIRROE := ""
Local _cUfMVA := U_ITGetMV("IT_UFSMVA","PR") 
Local _cTRIBMVA := U_ITGetMV("IT_TRIBMVA","023")
Local _nLimeteAp

Private _cMensagem	:= ""
Private _lAuto		:= FunName() == "MOMS003"
Private _lVarLog	:= Type("_aLogM003") == "A"

//==================================================================
// Valida permissão do usuário para incluir ou alterar um cliente.
// Tendo como base o limite de crédito no cadastro de usuários. 
//==================================================================
If ! FWIsInCallStack("U_GP010VALPE") .And. ! FWIsInCallStack("IMPORTAFUN") .And. ! FWIsInCallStack("U_IMPCLI") .And. ! FWIsInCallStack("MOMS003L") .And. ! FWIsInCallStack("MOMS055I")

   _nLimeteAp :=  Posicione("ZZL",3,xFilial("ZZL")+AllTrim(__cUserId),"ZZL_VLMAXP") // ZZL_FILIAL+ZZL_CODUSU
   If ValType(_nLimeteAp) <> "N"
      _nLimeteAp := 0
   EndIf 
 
   If Inclui .And. _lRet
      If M->A1_LC > _nLimeteAp
         U_ITMsg("O Valor do limite de crédito deste cliente: " + AllTrim(Str(M->A1_LC,14,2)) + ", é superior ao limite permitido para este usuário incluir o cliente: " + AllTrim(Str(_nLimeteAp,14,2))+".","Atenção","",1)
         _lRet := .F.      
      EndIf 
   EndIf 

   If Altera .And. _lRet
      If M->A1_LC <> SA1->A1_LC 
         If M->A1_LC > _nLimeteAp
            U_ITMsg("O Valor do limite de crédito deste cliente: " + AllTrim(Str(M->A1_LC,14,2)) + ", é superior ao limite permitido para este usuário alterar o cliente: " + AllTrim(Str(_nLimeteAp,14,2))+".","Atenção","",1)
            _lRet := .F.      
         EndIf 
      EndIf 
   EndIf 
EndIf 

//===================================================
// Demais validações do Cadastro de Clientes.
//===================================================
If Inclui
	
	//================================================================================
	// Validação do código de Cliente gerado automaticamente
	//================================================================================
	_cQuery := " SELECT MAX(A1_COD) AS CODIGO "
	_cQuery += " FROM "+ RetSqlName( 'SA1' )
	_cQuery += " WHERE D_E_L_E_T_ = ' ' "
	
	If Select(_cAlias) > 0
		(_cAlias)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQuery ) , _cAlias , .T. , .F. )
	
	DBSelectArea( _cAlias )
 	(_cAlias)->( DBGoTop() )
	If (_cAlias)->( !Eof() )
		_cCodigo := (_cAlias)->CODIGO
	Else
		_cCodigo := StrZero( 0 , TamSX3("A1_COD")[01] )
	EndIf
	
	(_cAlias)->( DBCloseArea() )
	
    If _cCodigo == M->A1_COD

		//Verifica se existe o codigo do cliente com a mesma loja ja cadastrado.
		_cQry := " SELECT COUNT(*) AS CONTADOR "
		_cQry += " FROM " + RetSqlName("SA1") + " "
		_cQry += " WHERE A1_COD = '" + M->A1_COD + "' "
		_cQry += "   AND A1_LOJA = '" + M->A1_LOJA + "' "

		DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBCLI" , .T. , .F. )
		
		DBSelectArea("TRBCLI")
		TRBCLI->(DBGoTop())
		
		If TRBCLI->CONTADOR <> 0

			If _lAuto
				If _lVarLog
					aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"O código de cliente: " + M->A1_COD + " e Loja: " + M->A1_LOJA + " já existe." } )
				EndIf
			Else
				U_ITMsg("Este código de cliente já está em uso!","Validação Código","Favor digitar novamente o CPF/CNPJ.",1)
			EndIf
			
			_lRet := .F.

		EndIf
		
		DBSelectArea("TRBCLI")
		TRBCLI->(DBCloseArea())
	
	EndIf

	DBSelectArea( 'SA1' )
	SA1->( DBSetOrder (3) )
	If SA1->( DBSeek( xFilial("SA1") + M->A1_CGC ) )
	
		_cUser := RetCodUsr()
		
		DBSelectArea("ZZL")
		ZZL->( DBSetOrder(3) )
		If ZZL->( DBSeek( xFilial("ZZL") + _cUser ) )
		
			If ZZL->ZZL_INCCLI <> 'S'
				
				If _lAuto
					If _lVarLog
						aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"O usuário: " + Capital( UsrFullName( _cUser ) ) + " não tem permissão para incluir cliente que já possui cadastro com o mesmo CPF/CNPJ" } )
					EndIf
				Else
					U_ITMsg("O usuário "+ Capital( UsrFullName( _cUser ) ) +" não tem permissão para incluir um cliente que já possui cadastro com o mesmo CPF/CNPJ.",;
							"Validação usuário",;
							"Informar a área de TI/ERP solicitando a liberação!",1)
				EndIf
				
				_lRet := .F.
				
			EndIf
		
		Else

			If _lAuto
				If _lVarLog
					aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"O usuário: " + Capital( UsrFullName( _cUser ) ) + " não tem permissão para incluir cliente que já possui cadastro com o mesmo CPF/CNPJ" } )
				EndIf
			Else
				U_ITMsg("O usuário "+ Capital( UsrFullName( _cUser ) ) +" não tem permissão para incluir um cliente que já possui cadastro com o mesmo CPF/CNPJ.",;
						"Validação usuário",;
						"Informar a área de TI/ERP solicitando a liberação!",1)
			EndIf
			
			_lRet := .F.
			
		EndIf
		
	EndIf
	
	If _lRet .And. !IsInCallStack("U_AOMS014")
    	_lRet := MA030RIS()   
    EndIf
	
EndIf

If Inclui .Or. Altera
   
    
	//================================================================================
	// Validação do preenchimento do campo de e-mail. Rotina automatica não deve mostrar
	//================================================================================
	If !IsInCallStack("U_GP010VALPE") .And. !IsInCallStack("U_GP265VALPE")
		If Empty( M->A1_EMAIL ) .And. ( FunName() <> "MOMS003" ) .And. FUNNAME() <> "GPEA010"
			
			If _lAuto
				If _lVarLog
					aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"O campo E-Mail não foi preenchido no cliente: " + M->A1_COD + " loja: " + M->A1_LOJA + " nome: " + AllTrim(M->A1_NOME) + ". Não cadastre endereços genéricos." } )
				EndIf
			Else
				U_ITMsg('O campo "e-mail" não foi preenchido, esse campo não é obrigatório mas deve ser preenchido com um endereço válido!',;
						'Validação Email','Não cadastre endereços genéricos como "funcionarios@italac.com.br" ou nfe@italac.com.br', 3)
			EndIf		
	
		EndIf
	
		If Empty(M->A1_INSCR) .And. ( FunName() <> "MOMS003" ) .And. ( FunName() <> "GPEA010" )
	
			
			U_ITMsg('Preencher como ISENTO quando For dispensado de IE e deixar em branco quando For não contribuinte do ICMS.  ',;
					'Atenção','Dúvidas procurar departamento FISCAL.',2)
	
		EndIf
		
	EndIf

    _cTxtAux := LTrim( StrTran( M->A1_NOME , '	' , '' ) )
    
    If _cTxtAux <> M->A1_NOME

    	If _lAuto
   			If _lVarLog
	   			aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"O campo Nome não foi preenchido no cliente: " + M->A1_COD + " loja: " + M->A1_LOJA + "." } )
	   		EndIf
	   	Else
	   		U_ITMsg("Erro no preenchimento do campo Nome!","Validação de Nome","É necessário retirar os espaços em branco para prosseguir com o cadastro.",1)
	   	EndIf

   		_lRet := .F.
    EndIf
    
    _cTxtAux := LTrim( StrTran( M->A1_END , '	' , '' ) )
    
    If _cTxtAux <> M->A1_END
		
		If _lAuto
			If _lVarLog
				aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"O campo Endereço não foi preenchido no cliente: " + M->A1_COD + " loja: " + M->A1_LOJA + " nome: " + AllTrim(M->A1_NOME) + "." } )
			EndIf
		Else
			U_ITMsg("Erro no preenchimento do campo Endereço!","Validação de endereço","É necessário retirar os espaços em branco para prosseguir com o cadastro.",1)
		EndIf

   		_lRet := .F.
    EndIf
    
    _cTxtAux := LTrim( StrTran( M->A1_BAIRRO , '	' , "" ) )
    
    If _cTxtAux <> M->A1_BAIRRO
   		
   		If _lAuto
   			If _lVarLog
	   			aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"O campo Bairro não foi preenchido no cliente: " + M->A1_COD + " loja: " + M->A1_LOJA + " nome: " + AllTrim(M->A1_NOME) + "." } )
	   		EndIf
   		Else
   			U_ITMsg("Erro no preenchimento do campo Endereço!","Validação de endereço","É necessário retirar os espaços em branco para prosseguir com o cadastro.",1)
   		EndIf

   		_lRet := .F.
    EndIf
    
    _cTxtAux := LTrim( StrTran( M->A1_COMPLEM , '	' , "" ) )
    
    If M->A1_COMPLEM <> ' ' .And. _cTxtAux <> M->A1_COMPLEM
	   	
		If _lAuto
			If _lVarLog
				aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"O campo Complemento não foi preenchido no cliente: " + M->A1_COD + " loja: " + M->A1_LOJA + " nome: " + AllTrim(M->A1_NOME) + "." } )
			EndIf
  		Else
  			U_ITMsg("Erro no preenchimento do campo Complemento do Endereço!","Validação Endereço","É necessário retirar os espaços em branco para prosseguir com o cadastro.",1)
  		EndIf

	   	_lRet := .F.
    EndIf
    
    _cTxtAux := LTrim( StrTran( M->A1_INSCR , '	' , "" ) )
    
    If _cTxtAux <> AllTrim(M->A1_INSCR)
   		
   		If _lAuto
			If _lVarLog
				aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"O campo Inscrição Estadual não foi preenchido no cliente: " + M->A1_COD + " loja: " + M->A1_LOJA + " nome: " + AllTrim(M->A1_NOME) + "." } )
			EndIf
		Else
			U_ITMsg("Erro no preenchimento do campo Inscrição Estadual!","Validação de inscrição estadual","É necessário retirar os espaços em branco para prosseguir com o cadastro.",1)
		EndIf

   		_lRet := .F.
    EndIf
 	
    If _lRet .And. !IsInCallStack("U_AOMS014")
    	_lRet := MA030RIS() 
    EndIf

	//================================================================================
	// Validação da sitação cadastral do cliente, conforme retorno no mashups
	//================================================================================
	If _lMashup
		If M->A1_PESSOA <> "F" .And. M->A1_COD <> "000001"
			_cUser := RetCodUsr()
			
			DBSelectArea("ZZL")
			ZZL->( DBSetOrder(3) )
			If ZZL->( DBSeek( xFilial("ZZL") + _cUser ) )
				If ZZL->ZZL_LIBMAS == "S"
					_lLibMas := .T.
				EndIf
			EndIf
	
			If !_lLibMas
				If Inclui
					If (AllTrim(M->A1_I_SITRF) <> "ATIVO" .And. AllTrim(M->A1_I_SITRF) <> "REGULAR" .And. AllTrim(M->A1_I_SITRF) <> "APTO" .And. AllTrim(M->A1_I_SITRF) <> "ATIVA") .Or. _lExec
						If _lExec
							_lRet := .F.
							If IsInCallStack("U_MOMS003")
								aAdd( _aLogM003 , { Date() , Time() ,'Log' ,'É necessário realizar a consulta deste cadastro de Fornecedor na Receita Federal devido a periodicidade de consulta. A consulta deve ser realizada no menu: Ações Relacionadas -> Mashups.' } )
							Else
								U_ITMsg( "É necessário realizar a consulta deste cadastro na Receita Federal devido a periodicidade de consulta.","Validação Mashup","A consulta deve ser realizada no menu: Ações Relacionadas -> Mashups.",1 )
							EndIf
						Else
							_lRet := .F.
							If Empty(M->A1_I_SITRF)
								If IsInCallStack("U_MOMS003")
									aAdd( _aLogM003 , { Date() , Time() ,'Log' ,'É necessário realizar a consulta deste cadastro de Fornecedor na Receita Federal e se "Jurídico" no Sintegra também. A consulta pode ser realizada no menu: Ações Relacionadas -> Mashups.' } )
								Else
									U_ITMsg( "É necessário realizar a consulta deste cadastro na Receita Federal e se 'Jurídico' no Sintegra também.","Validação Mashup","A consulta pode ser realizada no menu: Ações Relacionadas -> Mashups.",1 )
								EndIf
							Else
								If IsInCallStack("U_MOMS003")
									aAdd( _aLogM003 , { Date() , Time() ,'Log' ,'Não é possível concluir a criação do cadastro de cliente, devido o status deste Fornecedor na Receita Federal estar como [' + AllTrim(A1_I_SITRF) + '].' } )
								Else
									U_ITMsg( 'Não é possível concluir o cadastro deste cliente, devido seu status na Receita Federal estar como [' + AllTrim(M->A1_I_SITRF) + '].' , "Validação Mashup",,1 )
								EndIf
							EndIf
						EndIf
					EndIf
				ElseIf Altera
					If (AllTrim(A1_I_SITRF) <> "ATIVO" .And. AllTrim(A1_I_SITRF) <> "REGULAR" .And. AllTrim(A1_I_SITRF) <> "APTO" .And. AllTrim(A1_I_SITRF) <> "ATIVA") .Or. _lExec
						If _lExec
							_lRet := .F.
							If IsInCallStack("U_MOMS003")
								aAdd( _aLogM003 , { Date() , Time() ,'Log' ,'É necessário realizar a consulta deste cadastro de Fornecedor na Receita Federal devido a periodicidade de consulta. A consulta deve ser realizada no menu: Ações Relacionadas -> Mashups.' } )
							Else
								U_ITMsg( 'É necessário realizar a consulta deste cadastro na Receita Federal devido a periodicidade de consulta.',"Validação Mashup",'A consulta deve ser realizada no menu: Ações Relacionadas -> Mashups.' , 1)
							EndIf
						Else
							_lRet := .F.
							If Empty(A1_I_SITRF)
								If IsInCallStack("U_MOMS003")
									aAdd( _aLogM003 , { Date() , Time() ,'Log' ,'É necessário realizar a consulta deste cadastro de Fornecedor na Receita Federal e se "Jurídico" no Sintegra também. A consulta pode ser realizada no menu: Ações Relacionadas -> Mashups.' } )
								Else
									U_ITMsg( 'É necessário realizar a consulta deste cadastro na Receita Federal e se "Jurídico" no Sintegra também.',"Validação Mashup",'A consulta pode ser realizada no menu: Ações Relacionadas -> Mashups.' , 1 )
								EndIf
							Else
								If IsInCallStack("U_MOMS003")
									aAdd( _aLogM003 , { Date() , Time() ,'Log' ,'Não é possível concluir a criação do cadastro de cliente, devido o status deste Fornecedor na Receita Federal estar como [' + AllTrim(A1_I_SITRF) + '].' } )
								Else
									U_ITMsg( 'Não é possível concluir o cadastro deste cliente, devido seu status na Receita Federal estar como [' + AllTrim(A1_I_SITRF) + '].' ,"Validação Mashup",,1 )
								EndIf
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
EndIf


//================================================================================
//Validação de campos Chep
//================================================================================
If _lRet .And. M->A1_I_CHEP  == "C" .And. Len(AllTrim(A1_I_CCHEP)) != 10

	U_ITMsg("Campo de código de cadastro chep inválido!","Validação Chep","Mude cliente para pallet pbr ou inclua código Chep válido!",1)
	_lRet := .F.
	
EndIf

If _lRet .And. M->A1_I_CHEP  != "C" .And. Len(AllTrim(A1_I_CCHEP)) > 0 

	U_ITMsg("Campo de código de cadastro chep prenchido para cliente não Chep!","Validação Chep","Mude cliente para chep pbr ou limpe o código Chep válido!",1)
	_lRet := .F.
	
EndIf

If !IsInCallStack("U_AOMS014")
	If !Empty(M->A1_INSCR)
		M->A1_INSCR := AllTrim(StrTran(M->A1_INSCR,"-",""))
	EndIf
    
	//==========================================================================
	// Quando o cliente For alterado para Simples Nacional == NÃO, 
	// Limpar código de tabela de preços Simples Nacional do campo A1_TABELA.
	//==========================================================================
	If _lRet .And. Altera
       If SA1->A1_SIMPNAC == "1" .And. M->A1_SIMPNAC == "2"
          U_M30PALTAB(.T.)
	   Else
	      U_M30PALTAB(.F.)
	   EndIf 
	EndIf 
EndIf

If _lRet .And. !Empty(AllTrim(_cGrpGen)) .And. !Empty(AllTrim(_cVendGen))

	If M->A1_I_GRCLI $ _cGrpGen .And. IsInCallStack("MATA030") .And. !(M->A1_VEND $ _cVendGen)
		
		U_ITMsg("A efetivação não será realizada!"+Chr(13)+Chr(10)+"Para este grupo de clientes "+M->A1_I_GRCLI+" só é permito vincular os vendedores genéricos: "+_cVendGen,"Atenção","Altere o vendedor para um que seja genérico conforme informado.",1)
		_lRet := .F.	

	EndIf

EndIf

If _lRet .And. Altera
   //===================================================================================
   // Verifica se houve alterações nos Vendedores para envio de Workflow para o
   // Responsável. Chamado 25540.
   //===================================================================================
   If (M->A1_VEND <> SA1->A1_VEND ;
      .Or. M->A1_I_VEND2 <> SA1->A1_I_VEND2;
      .Or. M->A1_I_VEND3 <> SA1->A1_I_VEND3;
      .Or. M->A1_I_VEND4 <> SA1->A1_I_VEND4)
          
      _aListaVend := {} 

      _cEnvWorkF  := Posicione("ACY",1,xFilial("ACY")+M->A1_GRPVEN,"ACY_I_ALTV") // 1 = ACY_FILIAL+ACY_GRPVEN 
      _cNomeGrupo := Posicione("ACY",1,xFilial("ACY")+M->A1_GRPVEN,"ACY_DESCRI")

	  If _cEnvWorkF == "S"

         If M->A1_VEND <> SA1->A1_VEND
            _cNomVendA := Posicione("SA3",1,xFilial("SA3")+SA1->A1_VEND,"A3_NOME")
            _cNomVendB := Posicione("SA3",1,xFilial("SA3")+M->A1_VEND,"A3_NOME")
		    aAdd(_aListaVend,{M->A1_GRPVEN,_cNomeGrupo, SA1->A1_VEND,_cNomVendA,M->A1_VEND,_cNomVendB,"Vendedor1"})
		 EndIf 

	     If M->A1_I_VEND2 <> SA1->A1_I_VEND2
            _cNomVendA := Posicione("SA3",1,xFilial("SA3")+SA1->A1_I_VEND2,"A3_NOME")
            _cNomVendB := Posicione("SA3",1,xFilial("SA3")+M->A1_I_VEND2,"A3_NOME")
		    aAdd(_aListaVend,{M->A1_GRPVEN,_cNomeGrupo, SA1->A1_I_VEND2,_cNomVendA,M->A1_I_VEND2,_cNomVendB,"Vendedor2"})
		 EndIf 

	     If M->A1_I_VEND3 <> SA1->A1_I_VEND3
            _cNomVendA := Posicione("SA3",1,xFilial("SA3")+SA1->A1_I_VEND3,"A3_NOME")
            _cNomVendB := Posicione("SA3",1,xFilial("SA3")+M->A1_I_VEND3,"A3_NOME")
		    aAdd(_aListaVend,{M->A1_GRPVEN,_cNomeGrupo, SA1->A1_I_VEND3,_cNomVendA,M->A1_I_VEND3,_cNomVendB,"Vendedor3"})
		 EndIf 

	     If M->A1_I_VEND4 <> SA1->A1_I_VEND4
            _cNomVendA := Posicione("SA3",1,xFilial("SA3")+SA1->A1_I_VEND4,"A3_NOME")
            _cNomVendB := Posicione("SA3",1,xFilial("SA3")+M->A1_I_VEND4,"A3_NOME")
		    aAdd(_aListaVend,{M->A1_GRPVEN,_cNomeGrupo, SA1->A1_I_VEND4,_cNomVendA,M->A1_I_VEND4,_cNomVendB,"Vendedor4"})
		 EndIf 

         U_M030WKFLOW(_aListaVend)
	  EndIf 
   EndIf  
EndIf 

//===================================================================================
// Realiza bloqueio de Cliente por desconto contratual. Chamado 30177.
//===================================================================================
If _lRet .And. (Altera .Or. Inclui)
   
   _cDescCont := Posicione("ACY",1,xFilial("ACY")+M->A1_GRPVEN,"ACY_I_DESC") // ACY_FILIAL+ACY_GRPVEN 
   _aBloqSA1 := {.F.,;          // Bloqueio por contrato
	             M->A1_MSBLQL,; // Bloqueio por Cliente
		         M->A1_I_BLQDC} // Bloqueio Contrato 

   If (AllTrim(_cDescCont) == "S" .And. Inclui) .Or. (Altera .And. M->A1_GRPVEN <> SA1->A1_GRPVEN .And. AllTrim(_cDescCont) == "S")
      
	   If U_ITMsg("O grupo de cliente informado para este cliente possui uma regra de desconto contratual de uso restrito," +; //If U_ITMsg("O grupo de cliente informado para este cliente possui uma regra de desconto contratual preexistente,"+;
	             " ao confirmar este cadastro o mesmo será bloqueado para análise do setor de contratos. "+ CRLF +;
				 " Deseja prosseguir?", "Atenção", "",2,2,2) // 3,2,2 
		 
		 //M->A1_MSBLQL  := "1"
		 M->A1_I_BLQDC := "1"
		 
		 //----------------------//
		 _aBloqSA1 := {.T.,;     // Bloqueio por contrato
		               "1",;     // Bloqueio por Cliente
					   "1"}      // Bloqueio Contrato
		 //----------------------//
      
	  Else
		 
		 _aBloqSA1 := {.F.,;          // Bloqueio por contrato
		               M->A1_MSBLQL,; // Bloqueio por Cliente
					   M->A1_I_BLQDC} // Bloqueio Contrato
         //-----------------------------------------------------------// 					   
		 _lRet := .F. 

      EndIf 

   EndIf 

EndIf 

If _lRet .And. (Altera .Or. Inclui)

	_cA1_NOME := M->A1_NOME
	If !Empty(AllTrim(M->A1_NOME))
		_lRet := U_CRMA980VCP(@_cA1_NOME   ,"A1_NOME")
		M->A1_NOME := _cA1_NOME
	EndIf

	_cA1_END := M->A1_END
	If _lRet .And. !Empty(AllTrim(_cA1_END))
		_lRet := U_CRMA980VCP(@_cA1_END    ,"A1_END")
		M->A1_END := _cA1_END
	EndIf

	_cA1_BAIRRO := M->A1_BAIRRO
	If _lRet .And. !Empty(AllTrim(_cA1_BAIRRO))
		_lRet := U_CRMA980VCP(@_cA1_BAIRRO ,"A1_BAIRRO")
		M->A1_BAIRRO := _cA1_BAIRRO
	EndIf

	_cA1_ENDCOB := M->A1_ENDCOB
	If _lRet .And. !Empty(AllTrim(_cA1_ENDCOB))
		_lRet := U_CRMA980VCP(@_cA1_ENDCOB ,"A1_ENDCOB")
		M->A1_ENDCOB := _cA1_ENDCOB
	EndIf

	_cA1_ENDREC := M->A1_ENDREC
	If _lRet .And. !Empty(AllTrim(_cA1_ENDREC))
		_lRet := U_CRMA980VCP(@_cA1_ENDREC ,"A1_ENDREC")
		M->A1_ENDREC := _cA1_ENDREC
	EndIf

	_cA1_ENDENT := M->A1_ENDENT
	If _lRet .And. !Empty(AllTrim(_cA1_ENDENT))
		_lRet := U_CRMA980VCP(@_cA1_ENDENT,"A1_ENDENT")
		M->A1_ENDENT := _cA1_ENDENT
	EndIf

	_cA1_BAIRROE := M->A1_BAIRROE
	If _lRet .And. !Empty(AllTrim(_cA1_BAIRROE))
		_lRet := U_CRMA980VCP(@_cA1_BAIRROE,"A1_BAIRROE")
		M->A1_BAIRROE := _cA1_BAIRROE
	EndIf

    If M->A1_EST $ _cUfMVA .And. M->A1_SIMPNAC == "1" // 1=Sim;2=Não
	   M->A1_GRPTRIB := _cTRIBMVA //"023" //  Motivo: estado reduz o MVA para 30% (exceção fiscal) e estamos iniciando operação de 4 Brokers que atenderão este grupo.
	Else 
       If  AllTrim(M->A1_GRPTRIB) == AllTrim(_cTRIBMVA)
           M->A1_GRPTRIB :=  " "
       EndIf 
	EndIf 
	
EndIf

If _lRet .And. (Altera .Or. Inclui) .And. !IsInCallStack("U_AOMS014") .And. !IsInCallStack("U_MOMS003")
   If M->A1_PESSOA <> "F" .And. (Empty(AllTrim(M->A1_CNAE)) .Or. M->A1_CNAE == "    - /  ")
		U_ITMsg("Necessário o preenchimento do campo CNAE para Clientes pessoa Jurídica!","Atenção","",1)
		_lRet := .F.	
   EndIf
EndIf

If _lRet .And. (Altera .Or. Inclui) .And. !IsInCallStack("U_MOMS003") .And. ! FWIsInCallStack("IMPORTAFUN") .And. ! FWIsInCallStack("U_IMPCLI") .And. ! FWIsInCallStack("MOMS003L") .And. ! FWIsInCallStack("MOMS055I") .AND. !FWIsInCallStack("U_GP010VALPE") .And. !FWIsInCallStack("U_GP265VALPE")
	_lRet := U_CRMA980REP(M->A1_CGC,M->A1_COND,M->A1_GRPVEN,M->A1_I_NGRPC)
EndIf

FWRestArea( _aArea )

Return( _lRet )

/*
===============================================================================================================================
Programa----------: MA030RIS
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 22/06/2015
===============================================================================================================================
Descrição---------: Validaçao do grau de risco e limite de credito
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Lógico com exibição de mensagens para tratativa das negativas
===============================================================================================================================
*/
Static Function MA030RIS()
Local _aArea	:= FWGetArea()
Local _lRet		:= .T.
Local _cQry		:= ""
Local _cCliente	:= ""
Local _cLoja	:= ""
Local _cAlias	:= GetNextAlias()
Local _cQuery	:= ''
Local _aCliente	:= {}
Local _cLjvalid	:= ""
Local _aRecnos	:= {}
Local _lLimite	:= .F.
Local _lRisco	:= .F.
Local _nI		:= 0
		
Begin Sequence 
   
   If IsInCallStack("U_MOMS055") // Não validar msexecauto da integração do Broker.
      Break
   EndIf 

   _cCliente	:= M->A1_COD
   _cLoja		:= M->A1_LOJA
			
   _cQuery := " SELECT "
   _cQuery += " 	A1.A1_COD, A1.A1_LOJA, A1.A1_LC, A1.R_E_C_N_O_ AS SA1REG "
   _cQuery += " FROM "+ RetSqlName ("SA1")+ " A1  "
   _cQuery += " WHERE "
   _cQuery += " 		A1.D_E_L_E_T_	= ' ' "
   _cQuery += " AND	A1.A1_LC		<> '0'   " 
   _cQuery += " AND	A1.A1_COD		= '"+ _cCliente + "' "
			
   If Select(_cAlias) > 0
	  (_cAlias)->( DBCloseArea() )
   EndIf
			
   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQuery ) , _cAlias , .T. , .F. )
		    
   DBSelectArea(_cAlias)
   (_cAlias)->( DBGoTop() )
   While (_cAlias)->( !Eof() )
			
	  If _cLoja <> (_cAlias)->A1_LOJA
    	 aAdd( _aCliente,	{ (_cAlias)->A1_LOJA }	)
    	 aAdd( _aRecnos,		{ (_cAlias)->SA1REG }	)
   	  EndIf
		    
      (_cAlias)->( DBSkip() )
   EndDo
		   	
   //================================================================================
   // Não permite gravar Limite se já tiver Limite gravado em outras Lojas. Rotina automatica não deve mostrar
   //================================================================================
   If Len( _aCliente ) > 0
			
	  If M->A1_LC <> 0 .And. ( FunName() <> "MOMS003" )
		 _lLimite := .T.
	  EndIf
      //================================================================================
      // Tratativa para o chamado - 5717 - Permitir gravar Prospect sem Limite
      //================================================================================
   ElseIf M->A1_LC == 0 .And. ( FunName() <> "AOMS016" ) 

	  If _lAuto
	     If _lVarLog
			aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"O campo Limite de Crédito não foi preenchido no cliente: " + M->A1_COD + " loja: " + M->A1_LOJA + " nome: " + AllTrim(M->A1_NOME) + ". É obrigatório o preencimento deste campo." } )
		 EndIf
	  Else
	   	 U_ITMsg("Limite de crédito não preenchido!","Validação Crédito","É obrigatório incluir um limite de crédito para o cliente.",1)
	  EndIf

	  _lRet := .F.
   EndIf
			
   (_cAlias)->( DBCloseArea() )

   // Verificacao se existe alguma loja deste cliente com o risco diferente do que está sendo informado
   _cQry := "SELECT COUNT(*) AS QTDENT "
   _cQry += "FROM " + RetSqlName("SA1") + " "
   _cQry += "WHERE A1_FILIAL = '" + xFilial("SA1") + "' "
   _cQry += "  AND A1_COD = '" + M->A1_COD + "' "
   _cQry += "  AND A1_LOJA <> '" + M->A1_LOJA + "' "
   _cQry += "  AND A1_RISCO <> '" + M->A1_RISCO + "' "
   _cQry += "  AND D_E_L_E_T_ = ' ' "
	
   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQTD" , .T. , .F. )
	
   DBSelectArea("TRBQTD")
   TRBQTD->(DBGoTop())
		
   If TRBQTD->QTDENT > 0
	  _lRisco := .T.
   EndIf

   DBSelectArea("TRBQTD")
   TRBQTD->(DBCloseArea())	

   If _lLimite .And. !_lRisco

	  _cLjvalid := ""
		   			
	  For _nI := 1 to Len( _aCliente )
					
		  If _nI == Len( _aCliente )
		     _cLjvalid  += _aCliente[_nI][01]
		  Else
			 _cLjvalid  += _aCliente[_nI][01] + "; "
		  EndIf
						
	  Next _nI
		
	  If U_ITMsg("A(s) Loja(s) " + _cLjvalid + " do cliente " + AllTrim(Posicione("SA1", 1, xFilial("SA1") + M->A1_COD + M->A1_LOJA, "A1_NOME")) + ;
	 			" já possui(em) valor(es) de Limite(s) cadastrado(s), como o valor de Limite é compartilhado entre as lojas somente uma loja deverá ter limite estabelecido!",;
	 			"Validação Crédito","Deseja manter este limite de crédito compartilhado para todas as lojas? O sistema irá zerar o limite de crédito das outras lojas.",2,2,2)
		 VLDLIM(_lLimite, _aCliente, _aRecnos)
	  Else
	     If _lAuto
			If _lVarLog
		 	   aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"As lojas: " + _cLjvalid + " do cliente: " + M->A1_COD + " loja: " + M->A1_LOJA + " nome: " + AllTrim(M->A1_NOME) + ", já possui(em) valor(es) de Limite(s) cadastrado(s)." } )
			EndIf
		 EndIf
		 _lRet := .F.
	  EndIf
   ElseIf !_lLimite .And. _lRisco

	  If !IsInCallStack("U_MOMS003")
		
		 If U_ITMsg("Erro no Grau de Risco informado para o cliente - " + AllTrim(Posicione("SA1", 1, xFilial("SA1") + M->A1_COD + M->A1_LOJA, "A1_NOME")) + chr(10) + chr(13) + ;
	 			"É necessário verificar o cadastro deste cliente, pois existem outras lojas com o Grau de Risco diferente deste cadastro.",;
	 			"Validação Crédito","Deseja replicar este Risco para todas as lojas?",2,2,2)
		
		    VLDRIS()
		 Else
		    _lRet := .F.
		 EndIf
	  Else
		 If _lAuto
			If _lVarLog
			   aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"Erro no Grau de Risco informado no cliente: " + M->A1_COD + " loja: " + M->A1_LOJA + " nome: " + AllTrim(M->A1_NOME) + ", existem outras lojas com o Grau de Risco diferente deste cadastro." } )
			EndIf
		 EndIf
		 _lRet := .F.
	  EndIf
   ElseIf _lLimite .And. _lRisco

	  _cLjvalid := ""
		   			
	  For _nI := 1 to Len( _aCliente )
					
		  If _nI == Len( _aCliente )
			 _cLjvalid  += _aCliente[_nI][01]
		  Else
			 _cLjvalid  += _aCliente[_nI][01] + "; "
		  EndIf
						
	  Next _nI
	
	  If U_ITMsg("A(s) Loja(s) " + _cLjvalid + " do cliente - " + AllTrim(Posicione("SA1", 1, xFilial("SA1") + M->A1_COD + M->A1_LOJA, "A1_NOME")) + ;
				"já possui(em) valor(es) de Limite(s) cadastrado(s), como o valor de Limite é compartilhado entre as lojas somente uma loja deverá ter limite estabelecido!",;
				"Validação de limite de crédito","Deseja manter este Grau de Risco e limite de crédito compartilhado para todas as lojas? O sistema irá zerar o limite de crédito das outras lojas.",2,2,2)
				
		 VLDLIM(_lLimite, _aCliente, _aRecnos)
	  	 VLDRIS()
	  Else
		 If _lAuto
			If _lVarLog
				aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"As lojas: " + _cLjvalid + " do cliente: " + M->A1_COD + " loja: " + M->A1_LOJA + " nome: " + AllTrim(M->A1_NOME) + ", já possui(em) valor(es) de Limite(s) cadastrado(s)." } )
				aAdd( _aLogM003 , { Date() , Time() ,"Erro" ,"Erro no Grau de Risco informado no cliente: " + M->A1_COD + " loja: " + M->A1_LOJA + " nome: " + AllTrim(M->A1_NOME) + ", existem outras lojas com o Grau de Risco diferente deste cadastro." } )
			EndIf
		 EndIf
		 _lRet := .F.
	  EndIf
   EndIf

End Sequence 

FWRestArea(_aArea)

Return(_lRet)

/*
===============================================================================================================================
Programa----------: VLDLIM
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 23/06/2015
===============================================================================================================================
Descrição---------: Funcao para zerar o limite de credito, caso uma outra loja ja o tenha
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function VLDLIM(_lLimite, _aCliente, _aRecnos)

Local _nI		:= 0

If _lLimite
	If M->A1_LC > 0
		DBSelectArea("SA1")
		For _nI := 1 To Len( _aRecnos )
			DBGoTo( _aRecnos[_nI][01] )
			RecLock("SA1", .F.)
				Replace SA1->A1_LC With 0
				MSUnLock()
		Next _nI
	EndIf
EndIf

Return

/*
===============================================================================================================================
Programa----------: VLDLIM
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 23/06/2015
===============================================================================================================================
Descrição---------: Funcao para gravar o mesmo grau de risco para todas as lojas
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function VLDRIS()
Local _cQry	:= ""

// Seleciona todos as lojas do cliente em questao, para que sejam atualizados os riscos em todos os registros deste cliente
_cQry := "SELECT A1_FILIAL, A1_COD, A1_LOJA, R_E_C_N_O_ AS RECSA1 "
_cQry += "FROM " + RetSqlName("SA1") + " "
_cQry += "WHERE A1_FILIAL = '" + xFilial("SA1") + "' "
_cQry += "  AND A1_COD = '" + M->A1_COD + "' "
_cQry += "  AND A1_LOJA <> '" + M->A1_LOJA + "' " 
_cQry += "  AND D_E_L_E_T_ = ' ' "
			
DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBSA1" , .T. , .F. )
					
DBSelectArea("TRBSA1")
TRBSA1->(DBGoTop())
					
While !TRBSA1->(Eof())
	DBSelectArea("SA1")
	DBGoTo(TRBSA1->RECSA1)
	RecLock("SA1", .F.)
		Replace SA1->A1_RISCO With M->A1_RISCO
	MSUnLock()
	TRBSA1->(DBSkip())
End
					
DBSelectArea("TRBSA1")
TRBSA1->(DBCloseArea())

Return

/*
===============================================================================================================================
Programa----------: M030WKFLOW()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 20/12/2021
===============================================================================================================================
Descrição---------: Rotina de envio de e-mail WorkFlow notificando a alteração dos vendedores. Chamado 25540.
===============================================================================================================================
Parametros--------: _aDados = {{ Rede , Nome Rede, Cod Vend. Anterior, Nome Vend. Anterior, Cod. Vend.Atual, Nome Vend.Atual},
                           ...,{ Rede , Nome Rede, Cod Vend. Anterior, Nome Vend. Anterior, Cod. Vend.Atual, Nome Vend.Atual}} 
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function M030WKFLOW(_aDados)
Local _aConfig	:= U_ITCFGEML('')
Local _cMsgEml	:= '',_nI 
Local _cAssunto := "WORKFLOW - ALTERAÇÃO DE VENDEDOR EM CLIENTE COM CONTROLE DE REDE"
Local _cEmail1	:= AllTrim(U_ITGETMV("IT_EMALGP1",""))
Local _cEmail2	:= AllTrim(U_ITGETMV("IT_EMALGP2",""))
Local _cEmailEnv, _cEmlLog := "" 

If Empty(_cEmail1) .And. Empty(_cEmail2)
   Return 
EndIf 

_cEmailEnv := AllTrim(_cEmail1) + ";" + AllTrim(_cEmail2)

_cMsgEml := '<html>'
_cMsgEml += '<head><title>' + _cAssunto + '</title></head>'
_cMsgEml += '<body>'
_cMsgEml += '<style Type="text/css"><!--'
_cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
_cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
_cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
_cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }'
_cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFFFF; }'
_cMsgEml += 'td.aceito	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #00CC00; }'
_cMsgEml += 'td.recusa  { font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FF0000; }'
_cMsgEml += 'td.AZUL    { font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #0000FF; }'
_cMsgEml += 'td.amarelo { font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFF00; }'
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
_cMsgEml += '      <td align="center" colspan="2" class="grupos" width="100%"><b>' + _cAssunto + '</b></td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="grupos" align="left" width="20%"><b>Cliente:</b></td>'
_cMsgEml += '      <td class="itens" align="left" width="80%">' + SA1->A1_COD +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Loja:</b></td>'
_cMsgEml += '      <td class="itens" align="left" width="65%">' + SA1->A1_LOJA +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Nome:</b></td>'
_cMsgEml += '      <td class="itens" align="left width="65%">' + SA1->A1_NOME +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Rede:</b></td>'
_cMsgEml += '      <td class="itens" align="left" width="65%">' + _aDados[01][01] +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Descrição Rede:</b></td>'
_cMsgEml += '      <td class="itens" align="left" width="65%">' + _aDados[01][02]  +'</td>'
_cMsgEml += '    </tr>'
//_cMsgEml += '    <tr>'
//_cMsgEml += '      <td class="itens" align="center" width="20%"><b>Usuario:</b></td>'
//_cMsgEml += '      <td class="itens" align="left" >' + __cUserId +'</td>'
//_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Usuario Alterador:</b></td>'
_cMsgEml += '      <td class="itens" align="left" width="65%">' + UsrFullName (__cUserId)  +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Data da Alteração:</b></td>'
_cMsgEml += '      <td class="itens" align="left" width="65%">' + DToC(Date()) +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Hora da Alteração:</b></td>'
_cMsgEml += '      <td class="itens" align="left" width="65%">' + Time() + '</td>'
_cMsgEml += '    </tr>'
_cMsgEml += ' <tr>'
_cMsgEml += '   <td class="titulos" align="center" colspan="2"><font color="red">Esta é uma mensagem automática. Por favor não responder!</font></td>'
_cMsgEml += ' </tr>'
_cMsgEml += '</table>'

_cMsgEml += '<br>'
_cMsgEml += '<table class="bordasimples" width="1300">'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="grupos" align="center" width=10%"><b>Codigo Vendedor Anterior</b></td>'
_cMsgEml += '      <td class="grupos" align="center" width=25%"><b>Nome Vendedor Anterior</b></td>'
_cMsgEml += '      <td class="grupos" align="center" width=10%"><b>Codigo Vendedor Atual</b></td>'
_cMsgEml += '      <td class="grupos" align="center" width=25%"><b>Nome Vendedor Atual</b></td>'
_cMsgEml += '      <td class="grupos" align="center" width=25%"><b>Vendedor Alterado</b></td>'
_cMsgEml += '    </tr>'

For _nI := 1 To Len( _aDados )
	_cMsgEml += '    <tr>'
    _cMsgEml += '     <td class="itens" align="left" width="10%">'+_aDados[_nI][03]+'</td>'
	_cMsgEml += '     <td class="itens" align="left" width="25%">'+_aDados[_nI][04]+'</td>'
	_cMsgEml += '     <td class="itens" align="left" width="10%">'+_aDados[_nI][05]+'</td>'
	_cMsgEml += '     <td class="itens" align="left" width="25%">'+_aDados[_nI][06]+'</td>'
	_cMsgEml += '     <td class="itens" align="left" width="25%">'+_aDados[_nI][07]+'</td>'
	_cMsgEml += '    </tr>'
Next _nI
	
_cMsgEml += '</table>'

U_ITConOut('Enviando E-mail(s) para: '+_cEmailEnv+ " - Log de Processamento - Vendedores Alterados - "+TIME()+" - [ M030PALT]")

//    ITEnvMail(cFrom     ,cEmailTo ,_cEmailCo,cEmailBcc,cAssunto ,cMensagem,cAttach   ,cAccount    ,cPassword   ,cServer      ,cPortCon    ,lRelauth     ,cUserAut     ,cPassAut     ,cLogErro)
U_ITENVMAIL( _aConfig[01] , _cEmailEnv ,"",         ,_cAssunto, _cMsgEml ,         ,_aConfig[01],_aConfig[02], _aConfig[03],_aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )

Return .T.

/*
===============================================================================================================================
Programa----------: MA30RETA
Autor-------------: Julio de Paula Paz
Data da Criacao---: 23/12/2021
===============================================================================================================================
Descrição---------: Retorna a variáStaticatic _aBloqSA1 para outros programas. Chamado 30177.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: _aRet = Conteúdo da variáStaticatic _aBloqSA1.
===============================================================================================================================
*/
User Function MA30RETA()
Local _aRet :={}

Begin Sequence 

   _aRet := AClone(_aBloqSA1)

End Sequence 

Return _aRet
