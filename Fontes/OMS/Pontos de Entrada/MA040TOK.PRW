/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor            |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich      | 10/10/2018 | Zera porcentual de comissão para sup/coord/ger conflitante - Chamado 26437     
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich      | 27/02/2019 | Bloqueia regras de comissão se o vendedor é bloqueado - Chamado 28112      
-------------------------------------------------------------------------------------------------------------------------------
 Lucas Borges     | 11/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
------------------------------------------------------------------------------------------------------------------------------
 Julio Paz        | 21/01/2021 | Inclusão das comissões do novo Gerente Nacional. Chamado 35183.  
------------------------------------------------------------------------------------------------------------------------------
 Julio Paz        | 17/12/2021 | Inclusão de logs para registrar a inclusão, alteração e exclusão de Vendedores. Chamado 35404
------------------------------------------------------------------------------------------------------------------------------
 Alex Wallauer    | 21/12/2021 | Acerto do SELECT da comissao do gerente nacional . Chamado 34402
------------------------------------------------------------------------------------------------------------------------------
 Alex Wallauer    | 19/09/2023 | Inclusão FWRestArea() após Posicione (Gerente) que desposionava o registro
==============================================================================================================================================================
Analista - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
==============================================================================================================================================================
Antônio  - Julio Paz     - 11/02/25 - 12/02/25 - 49868   - Ajustar as validações do cadastro de Vendedores/supervisores/coordenadores/gerentes/gerente nacional. Para gerente nacional permitir os campos coordenadores e gerentes vazios.
==============================================================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "TopConn.ch"

Static _aLogSA3 := {}

/*
===============================================================================================================================
Programa----------: MA040TOK
Autor-------------: Talita Teixeira
Data da Criacao---: 08/07/2013
===============================================================================================================================
Descrição---------: P.E. na validação do cadastro de Vendedores
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Lógico (.T./.F.) para definir se o registro pode ser gravado
===============================================================================================================================
*/
User Function MA040TOK

Local _aArea   	:= FWGetArea()
Local _lRet		:= .T.
Local _lSqlOk	:= .T.

Local _cCod		:= M->A3_COD
Local _cCodSup	:= M->A3_SUPER
Local _cCodGer	:= M->A3_GEREN
Local _cCodSui	:= M->A3_I_SUPE
Local _cTipVen	:= M->A3_I_TIPV
Local _cCodGNac := M->A3_I_GERNC

Local _cQuery	:= ""
Local _cAlias	:= GetNextAlias()

//Se não veio do tudook já retorna .T.
If !(isincallstack("A040TUDOOK"))
	Return .T.
EndIf

//=========================================================================================
// Valida a região. 
//=========================================================================================
If _lRet .And. M->A3_I_REG == "BR" .And. M->A3_I_TIPV <> "N"
	U_ITMsg("A área de atuação Brasil é exclusiva para o tipo de vendedor Gerente Nacional!","Atenção","Escolha uma área de atuação diferente de Brasil para o vendedor, supervisor, coordenador e Gerente.",1)
	_lRet := .F.
EndIf

//=========================================================================================
//Validação de campos supervisor, coordenador, gerente e gerente nacional preenchidos    
//=========================================================================================
If _lRet .And. Empty(M->A3_SUPER) .And. M->A3_I_TIPV != 'C' .And. M->A3_I_TIPV != 'G' .And. M->A3_I_TIPV != 'N' 
	U_ITMsg("Coordenador não preenchido!","Atenção","Escolha um código para o coordenador",1) 
	_lRet := .F.
EndIf

If _lRet .And. Empty(M->A3_GEREN) .And. M->A3_I_TIPV != 'G' .And. M->A3_I_TIPV != 'N' 
	U_ITMsg("Gerente não preenchido!","Atenção","Escolha um código para o gerente",1) 
	_lRet := .F.
EndIf

If _lRet .And. Empty(M->A3_I_GERNC) .And. M->A3_I_TIPV != 'N'  
	U_ITMsg("Gerente Nacional não preenchido!","Atenção","Escolha um código para o gerente nacional.",1)
	_lRet := .F.
EndIf

//====================================================================================================
// Validação de campos supervisor, coordenador, gerente e gerente nacional incorretamente preenchidos
//====================================================================================================
If _lRet .And. !Empty(M->A3_SUPER) .And. ( M->A3_I_TIPV == 'C' .Or. M->A3_I_TIPV == 'G')
	U_ITMsg("Coordenador preenchido!","Atenção","Deixe coordenador vazio para vendedor tipo coordenador e gerente",1)
	_lRet := .F.
EndIf
If _lRet .And. !Empty(M->A3_I_SUPE) .And. ( M->A3_I_TIPV == 'S' .Or. M->A3_I_TIPV == 'C' .Or. M->A3_I_TIPV == 'G')
	U_ITMsg("Supervisor preenchido!","Atenção","Deixe supervisor vazio para vendedor tipo supervisor/coordenador/gerente",1)
	_lRet := .F.
EndIf
If _lRet .And. !Empty(M->A3_GEREN) .And. M->A3_I_TIPV = 'G' 
	U_ITMsg("Gerente preenchido!","Atenção","Deixe gerente vazio para vendedor tipo gerente",1)
	_lRet := .F.
EndIf

If _lRet .And. !Empty(M->A3_I_GERNC) .And. M->A3_I_TIPV = 'N' 
	U_ITMsg("Gerente Nacional preenchido!","Atenção","Deixe gerente nacional vazio para vendedor tipo gerente nacional.",1)
	_lRet := .F.
EndIf

//=============================================================================================================
//Validação de campos supervisor, coordenador, gerente e gerente nacional diferentes do campo do vendedor
// e entre si
//=============================================================================================================
If _lRet .And. M->A3_SUPER == M->A3_COD .And. !Empty(M->A3_SUPER)
	U_ITMsg("Coordenador não pode ter o mesmo código do vendedor!","Atenção","Escolha um código diferente para o coordenador",1)
	_lRet := .F.
EndIf
If _lRet .And. M->A3_I_SUPE == M->A3_COD .And. !Empty(M->A3_I_SUPE)
	U_ITMsg("Supervisor não pode ter o mesmo código do vendedor!","Atenção","Escolha um código diferente para o Supervisor",1)
	_lRet := .F.
EndIf
If _lRet .And. M->A3_GEREN == M->A3_COD .And. !Empty(M->A3_GEREN)
	U_ITMsg("Gerente não pode ter o mesmo código do vendedor!","Atenção","Escolha um código diferente para o gerente",1)
	_lRet := .F.
EndIf

If _lRet .And. M->A3_I_GERNC == M->A3_COD .And. !Empty(M->A3_I_GERNC)
	U_ITMsg("Gerente Nacional não pode ter o mesmo código do vendedor!","Atenção","Escolha um código diferente para o gerente nacional.",1)
	_lRet := .F.
EndIf

If _lRet .And. M->A3_I_SUPE == M->A3_GEREN .And. !Empty(M->A3_I_SUPE)
	U_ITMsg("Supervisor não pode ter o mesmo código do gerente!","Atenção","Escolha um código diferente para o Supervisor ou gerente",1)
	_lRet := .F.
EndIf
If _lRet .And. M->A3_SUPER == M->A3_GEREN .And. !Empty(M->A3_SUPER)
	U_ITMsg("Coordenador não pode ter o mesmo código do gerente!","Atenção","Escolha um código diferente para o coordenador ou gerente",1)
	_lRet := .F.
EndIf
If _lRet .And. M->A3_SUPER == M->A3_I_SUPE .And. !Empty(M->A3_I_SUPE)
	U_ITMsg("Coordenador não pode ter o mesmo código do Supervisor!","Atenção","Escolha um código diferente para o coordenador ou supervisor",1)
	_lRet := .F.
EndIf

If _lRet .And. M->A3_I_SUPE == M->A3_I_GERNC .And. !Empty(M->A3_I_SUPE)
	U_ITMsg("Supervisor não pode ter o mesmo código do gerente nacional!","Atenção","Escolha um código diferente para o Supervisor ou gerente nacioanl.",1)
	_lRet := .F.
EndIf
If _lRet .And. M->A3_SUPER == M->A3_I_GERNC .And. !Empty(M->A3_SUPER)
	U_ITMsg("Coordenador não pode ter o mesmo código do gerente nacional!","Atenção","Escolha um código diferente para o coordenador ou gerente nacional.",1)
	_lRet := .F.
EndIf
If _lRet .And. M->A3_I_GERNC == M->A3_GEREN .And. !Empty(M->A3_I_GERN)
	U_ITMsg("Gerente não pode ter o mesmo código do Gerente nacioanl!","Atenção","Escolha um código diferente para o gerente ou gerente nacioanal.",1)
	_lRet := .F.
EndIf

//=========================================================================================
//Validação de campos supervisor, coordenador e gerente com tipo correto
//=========================================================================================
If _lRet .And. !Empty(M->A3_SUPER) .And. Posicione("SA3",1,xFilial("SA3")+M->A3_SUPER,"A3_I_TIPV") != "C"
	U_ITMsg("Coordenador indicou um código de vendedor com tipo diferente de coordenador!","Atenção","Escolha um código de coordenador",1)
	_lRet := .F.
EndIf
If _lRet .And. !Empty(M->A3_I_SUPE) .And. Posicione("SA3",1,xFilial("SA3")+M->A3_I_SUPE,"A3_I_TIPV") != "S"
	U_ITMsg("Supervisor indicou um código de vendedor com tipo diferente de supervisor!","Atenção","Escolha um código de Supervisor",1)
	_lRet := .F.
EndIf
If _lRet .And. !Empty(M->A3_GEREN) .And. Posicione("SA3",1,xFilial("SA3")+M->A3_GEREN,"A3_I_TIPV") != "G"
	U_ITMsg("Gerente indicou um código de vendedor com tipo diferente de gerente!","Atenção","Escolha um código de gerente",1)
	_lRet := .F.
EndIf

If _lRet .And. !Empty(M->A3_I_GERNC) .And. Posicione("SA3",1,xFilial("SA3")+M->A3_I_GERNC,"A3_I_TIPV") != "N"
	U_ITMsg("Gerente nacional indicou um código de vendedor com tipo diferente de gerente nacional!","Atenção","Escolha um código de gerente nacional.",1)
	_lRet := .F.
EndIf

FWRestArea(_aArea)
//=========================================================================================
//Validação de campo tipo em relação à outros cadastros
//=========================================================================================
If _lRet 

		_cQuery := " SELECT A3_COD,A3_NOME,A3_SUPER,A3_GEREN,A3_I_SUPE, A3_I_GERNC " 
		_cQuery += " FROM  "+ RetSqlName("SA3") +" SA3 "
		_cQuery += " WHERE "
		_cQuery += "     SA3.D_E_L_E_T_ = ' ' "
		_cQuery += " AND (  SA3.A3_SUPER   = '"+ _cCod +"' "
		_cQuery += "     OR SA3.A3_I_SUPE  = '"+ _cCod +"' "
		_cQuery += "     OR SA3.A3_GEREN   = '"+ _cCod +"' "
		_cQuery += "     OR SA3.A3_I_GERNC = '"+ _cCod +"' ) " 

		If Select(_cAlias) > 0
			(_cAlias)->( DBCloseArea() )
		EndIf

		DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias , .T. , .F. )

		DBSelectArea(_cAlias)
		(_cAlias)->( DBGoTop() )

		_alist := {}
		_cmens := ""

		While (_cAlias)->( !Eof() ) 
	
			//Analise para cadastro de vendedor
			If _cTipVen == 'V'
			
				If AllTrim((_cAlias)->A3_I_SUPE) == AllTrim(_cCod)
					aAdd(_alist,{"Consta como supervisor do vendedor " + (_cAlias)->A3_COD + " - " + (_cAlias)->A3_NOME })
					_cmens := "Cadastro não pode ser definido como vendedor pois já consta como supervisor/coordenador/gerente de outros vendedores!"
					_lRet := .F.
				EndIf
				If AllTrim((_cAlias)->A3_SUPER) == AllTrim(_cCod)
					aAdd(_alist,{"Consta como coordenador do vendedor " + (_cAlias)->A3_COD + " - " + (_cAlias)->A3_NOME })
					_cmens := "Cadastro não pode ser definido como vendedor pois já consta como supervisor/coordenador/gerente de outros vendedores!"
					_lRet := .F.
				EndIf
				If AllTrim((_cAlias)->A3_GEREN) == AllTrim(_cCod)
					aAdd(_alist,{"Consta como gerente do vendedor " + (_cAlias)->A3_COD + " - " + (_cAlias)->A3_NOME })
					_cmens := "Cadastro não pode ser definido como vendedor pois já consta como supervisor/coordenador/gerente de outros vendedores!"
					_lRet := .F.
				EndIf
			    
				If AllTrim((_cAlias)->A3_I_GERNC) == AllTrim(_cCod) 
					aAdd(_alist,{"Consta como gerente nacional do vendedor " + (_cAlias)->A3_COD + " - " + (_cAlias)->A3_NOME })
					_cmens := "Cadastro não pode ser definido como vendedor pois já consta como supervisor/coordenador/gerente/gerente nacional de outros vendedores!"
					_lRet := .F.
				EndIf

			EndIf
			
			//Analise para cadastro de supervisor
			If _cTipVen == 'S'
		
				If AllTrim((_cAlias)->A3_SUPER) == AllTrim(_cCod)
					aAdd(_alist,{"Consta como coordenador do vendedor " + (_cAlias)->A3_COD + " - " + (_cAlias)->A3_NOME })
					_cmens := "Cadastro não pode ser definido como supervisor pois já consta como coordenador/gerente de outros vendedores!"
					_lRet := .F.
				EndIf
				If AllTrim((_cAlias)->A3_GEREN) == AllTrim(_cCod)
					aAdd(_alist,{"Consta como gerente do vendedor " + (_cAlias)->A3_COD + " - " + (_cAlias)->A3_NOME })
					_cmens := "Cadastro não pode ser definido como supervisor pois já consta como coordenador/gerente de outros vendedores!"
					_lRet := .F.
				EndIf
			    
				If AllTrim((_cAlias)->A3_I_GERNC) == AllTrim(_cCod) 
					aAdd(_alist,{"Consta como gerente nacional do vendedor " + (_cAlias)->A3_COD + " - " + (_cAlias)->A3_NOME })
					_cmens := "Cadastro não pode ser definido como supervisor pois já consta como coordenador/gerente/gerente nacional de outros vendedores!"
					_lRet := .F.
				EndIf
			EndIf
			
			//Analise para cadastro de coordenador
			If _cTipVen == 'C'

				If AllTrim((_cAlias)->A3_I_SUPE) == AllTrim(_cCod)
					aAdd(_alist,{"Consta como supervisor do vendedor " + (_cAlias)->A3_COD + " - " + (_cAlias)->A3_NOME })
					_cmens := "Cadastro não pode ser definido como coordenador pois já consta como supervisor/gerente de outros vendedores!"
					_lRet := .F.
				EndIf
				If AllTrim((_cAlias)->A3_GEREN) == AllTrim(_cCod)
					aAdd(_alist,{"Consta como gerente do vendedor " + (_cAlias)->A3_COD + " - " + (_cAlias)->A3_NOME })
					_cmens := "Cadastro não pode ser definido como coordenador pois já consta como supervisor/gerente de outros vendedores!"
					_lRet := .F.
				EndIf

                If AllTrim((_cAlias)->A3_I_GERNC) == AllTrim(_cCod) 
					aAdd(_alist,{"Consta como gerente nacional do vendedor " + (_cAlias)->A3_COD + " - " + (_cAlias)->A3_NOME })
					_cmens := "Cadastro não pode ser definido como coordenador pois já consta como supervisor/gerente/gerente nacional de outros vendedores!"
					_lRet := .F.
				EndIf

			EndIf
			
			//Analise para cadastro de gerente
			If _cTipVen == 'G'
			
				If AllTrim((_cAlias)->A3_I_SUPE) == AllTrim(_cCod)
					aAdd(_alist,{"Consta como supervisor do vendedor " + (_cAlias)->A3_COD + " - " + (_cAlias)->A3_NOME })
					_cmens := "Cadastro não pode ser definido como gerente pois já consta como supervisor/coordenador de outros vendedores!"
					_lRet := .F.
				EndIf
				If AllTrim((_cAlias)->A3_SUPER) == AllTrim(_cCod)
					aAdd(_alist,{"Consta como coordenador do vendedor " + (_cAlias)->A3_COD + " - " + (_cAlias)->A3_NOME })
					_cmens := "Cadastro não pode ser definido como gerente pois já consta como supervisor/coordenador de outros vendedores!"
					_lRet := .F.
				EndIf
			    
				If AllTrim((_cAlias)->A3_I_GERNC) == AllTrim(_cCod) 
					aAdd(_alist,{"Consta como gerente nacional do vendedor " + (_cAlias)->A3_COD + " - " + (_cAlias)->A3_NOME })
					_cmens := "Cadastro não pode ser definido como gerente pois já consta como supervisor/coordenador/gerente nacional de outros vendedores!"
					_lRet := .F.
				EndIf
			
			EndIf
				
			//Analise para cadastro de gerente nacional
			If _cTipVen == 'N' 
			
				If AllTrim((_cAlias)->A3_I_SUPE) == AllTrim(_cCod)
					aAdd(_alist,{"Consta como supervisor do vendedor " + (_cAlias)->A3_COD + " - " + (_cAlias)->A3_NOME })
					_cmens := "Cadastro não pode ser definido como gerente pois já consta como supervisor/coordenador de outros vendedores!"
					_lRet := .F.
				EndIf
				If AllTrim((_cAlias)->A3_SUPER) == AllTrim(_cCod)
					aAdd(_alist,{"Consta como coordenador do vendedor " + (_cAlias)->A3_COD + " - " + (_cAlias)->A3_NOME })
					_cmens := "Cadastro não pode ser definido como gerente pois já consta como supervisor/coordenador de outros vendedores!"
					_lRet := .F.
				EndIf
			    
				If AllTrim((_cAlias)->A3_GEREN) == AllTrim(_cCod) 
					aAdd(_alist,{"Consta como gerente do vendedor " + (_cAlias)->A3_COD + " - " + (_cAlias)->A3_NOME })
					_cmens := "Cadastro não pode ser definido como gerente pois já consta como supervisor/coordenador/gerente de outros vendedores!"
					_lRet := .F.
				EndIf
			
			EndIf

			(_cAlias)->( DBSkip() ) 
			
		EndDo
		
		(_cAlias)->( DBCloseArea() )	
		
		If !_lRet
			
			If Len(_alist) > 0
			
				_aheader := {"Problemas"}
				U_ITListBox( _cmens , _aheader , _alist , .T. , 1 )

			EndIf
			
		EndIf
				
EndIf

//=========================================================================================
//Validação de regras de comissão e bloqueio se necessário
//=========================================================================================
If _lRet 
	
	_cQuery := " SELECT "
	_cQuery += "     COUNT(1) AS CONT "
	_cQuery += " FROM  "+ RetSqlName('ZAE') +" ZAE "
	_cQuery += " WHERE "
	_cQuery += "     ZAE.D_E_L_E_T_ = ' ' "
	_cQuery += " AND ZAE.ZAE_VEND   = '"+ _cCod +"' "
	_cQuery += " AND ( ZAE.ZAE_CODSUP <> '"+ _cCodSup +"' OR ZAE.ZAE_CODGER <> '"+ _cCodGer +"' OR ZAE.ZAE_CODSUI <> '"+ _cCodSui +"' OR ZAE.ZAE_CODGNC <> '"+ _cCodGNac +"' ) " 

	If Select(_cAlias) > 0
		(_cAlias)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias , .T. , .F. )
	
	DBSelectArea(_cAlias)
	(_cAlias)->( DBGoTop() )
	If ((_cAlias)->( !Eof() ) .And. (_cAlias)->CONT > 0 ) .Or. M->A3_MSBLQL == '1'
		
		_cQuery := " UPDATE "+ RetSqlName('ZAE') +" ZAE "
		_cQuery += " SET ZAE.ZAE_MSBLQL = '1' "
		_cQuery += " WHERE "
		_cQuery += "     ZAE.D_E_L_E_T_ = ' ' "
		_cQuery += " AND ZAE.ZAE_VEND   = '"+ _cCod +"' "
		
		_lSqlOk := !( TCSqlExec(_cQuery) < 0 )

/*		Alinhado com o Vanderson tava zerando somente atacado então deixa para zera os 2 na atualizacao da comissao

		//Zera porcentuais de supervisor conflitante
		_cQuery := " UPDATE "+ RetSqlName('ZAE') +" ZAE "
		_cQuery += " SET ZAE.ZAE_COMIS4 = 0 "
		_cQuery += " WHERE "
		_cQuery += "     ZAE.D_E_L_E_T_ = ' ' "
		_cQuery += " AND ZAE.ZAE_VEND   = '"+ _cCod +"' "
		_cQuery += " AND ZAE.ZAE_CODSUI <> '"+ _cCodSui  +"' "
		
		_lSqlOk :=  _lSqlOk .And. !( TCSqlExec(_cQuery) < 0 )
		
		//Zera porcentuais de COORDENADOR conflitante
		_cQuery := " UPDATE "+ RetSqlName('ZAE') +" ZAE "
		_cQuery += " SET ZAE.ZAE_COMIS2 = 0 "
		_cQuery += " WHERE "
		_cQuery += "     ZAE.D_E_L_E_T_ = ' ' "
		_cQuery += " AND ZAE.ZAE_VEND   = '"+ _cCod +"' "
		_cQuery += " AND ZAE.ZAE_CODSUP <> '"+ _cCodSup  +"' "
		
		_lSqlOk := !( TCSqlExec(_cQuery) < 0 )
		
		//Zera porcentuais de Gerente conflitante
		_cQuery := " UPDATE "+ RetSqlName('ZAE') +" ZAE "
		_cQuery += " SET ZAE.ZAE_COMIS3 = 0 "
		_cQuery += " WHERE "
		_cQuery += "     ZAE.D_E_L_E_T_ = ' ' "
		_cQuery += " AND ZAE.ZAE_VEND   = '"+ _cCod +"' "
		_cQuery += " AND ZAE.ZAE_CODGER <> '"+ _cCodger  +"' "
		
		_lSqlOk := !( TCSqlExec(_cQuery) < 0 )

		//Zera porcentuais de Gerente Nacional conflitante 
		_cQuery := " UPDATE "+ RetSqlName('ZAE') +" ZAE "
		_cQuery += " SET ZAE.ZAE_COMIS5 = 0 "
		_cQuery += " WHERE "
		_cQuery += "     ZAE.D_E_L_E_T_ = ' ' "
		_cQuery += " AND ZAE.ZAE_VEND   = '"+ _cCod +"' "
		_cQuery += " AND ZAE.ZAE_CODGNC <> '"+ _cCodGNac  +"' "
		
		_lSqlOk := !( TCSqlExec(_cQuery) < 0 )
*/
		If _lSqlOk
		
			U_ITMsg('Foi identificado que o cadastro das Regras de Comissão do Vendedor ficou divergente com relação à nova configuração!' , "Atenção",;
					'O cadastro das Regras foi Bloqueado e deverá ser revisado para a Liberação do mesmo.' ,1)
				
		Else
		
			U_ITMsg('Falha ao atualizar o cadastro das Regras de Comissão do Vendedor que ficou divergente com relação à nova configuração!' , "Atenção",;
					'O cadastro das Regras NÃO FOI BLOQUEADO e deverá ser revisado para permitir a gravação dessa alteração.' ,1)
					
			_lRet := .F.
			
		EndIf
			
	EndIf

	If Select(_cAlias) > 0
		(_cAlias)->( DBCloseArea() )
	EndIf
	
EndIf

If _lRet 
   If Type("ALTERA") <> "U" .And. ALTERA
      //=============================================================================
      // Carrega array com os campos do cadastro de Vendedores antes das Alterações.
      //=============================================================================
      _aLogSA3 := U_ITIniLog("SA3")  

   ElseIf Type("EXCLUI") <> "U" .And. EXCLUI 
      //=============================================================================
      // Carrega array com os campos do cadastro de Vendedores antes das Alterações.
      //=============================================================================
      _aLogSA3 := U_ITIniLog("SA3")  
   EndIf  

EndIf 

FWRestArea(_aArea)

Return( _lRet )

/*
===============================================================================================================================
Programa----------: MA040LOG
Autor-------------: Julio de Paula Paz
Data da Criacao---: 16/12/2021 
===============================================================================================================================
Descrição---------: Função que retorna o array estático de log de alteração
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: _aCmpLog = Array do Log de Alteração, com os dados antes das alterações / exclusão.
===============================================================================================================================
*/
User Function MA040LOG()
Local _aDados

Begin Sequence
   
   _aDados := Aclone(_aLogSA3)

End Sequencelse
	
Return _aDados  





