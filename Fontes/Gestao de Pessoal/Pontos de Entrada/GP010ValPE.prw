/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |09/08/2022| Chamado 40931. Na inclusão de funcionários, Gravar cad.Clientes: Segmento=39 e contribuinte=Não.
Alex Wallauer |13/09/2023| Chamado 45011. Ao realizar a "Alteração" de funcionários, NAO atualizar o campo A1_LC.
Lucas Borges  |04/09/2025| Chamado 51643. Incluída nova exceção para não processar o PE - AGPE003
==============================================================================================================================================================
Analista - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
==============================================================================================================================================================
Uidson    - Igor Melgaco  - 07/07/25 - 16/10/25 - 49804   - Ajustes para não mostrar janelas de erro qdo executado o ExecAuto de Funcionario pelo AGPE010
==============================================================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: GP010VALPE
Autor-------------: Tiago Correa Castro
Data da Criacao---: 05/11/2008
Descrição---------: Ponto de Entrada para validar a inclusao/alteracao no cadastro de funcionários
Parametros--------: Nenhum
Retorno-----------: lRet - Indica se o cadastro foi validado ou não.
===============================================================================================================================
*/
User Function GP010ValPE

Local _aArea 	:=  FWGetArea() As Array
Local _lRet		:= .T. As Logical
Local _cQuery	:= "%" As Character
Local _cCPF		:= M->RA_CIC As Character
Local _cSefip	:= M->RA_CATEG	As Character
Local _cCatFunc	:= M->RA_CATFUNC As Character//M:MENSALISTA, A=AUTONOMO, E=ESTAGIARIO, P=PRO-LABORE, ETC.  
Local _cMatric	:= M->RA_MAT As Character
Local _cAlias	:= GetNextAlias() As Character

If IsInCallStack('U_MGPE023') .Or. IsInCallStack('U_AGPE003')
   Return .T.
EndIf

Private _cCPFAnterior:=	M->RA_CIC

Begin Sequence

If Inclui
	_cQuery += " AND RA_CIC     = '"+ _cCPF		+"' %"
ElseIf Altera
    _cCPFAnterior:=SRA->RA_CIC
	_cQuery += " AND RA_MAT     <> '"+ _cMatric	+"' "
	_cQuery += " AND RA_CIC     = '"+ _cCPF		+"' %"
EndIf

BeginSql alias _cAlias
	SELECT COUNT(1) QTD FROM %Table:SRA%
	WHERE D_E_L_E_T_ = ' '
	AND RA_CATEG   = %exp:_cSefip%
	AND RA_CATFUNC = %exp:_cCatFunc%
	AND RA_SITFOLH <> 'D'
	AND RA_FILIAL = %xFilial:SRA%
	%exp:_cQuery%
EndSql
			
If (_cAlias)->QTD > 0
	If Inclui
		FWAlertWarning("Cadastro duplicado - Inclusao. Nao será possível a inclusao desse registro pois ja existe um registro com o mesmo CPF, Categ. SEFIP e Cat. Func. na base de Dados!! "+;
						" Favor verificar se os dados do Registro estão corretos!!","GP010VALPE01")
		_lRet := .F.
		Break
	ElseIf Altera .And. ( _cCPF <> Space(11) )
		FWAlertWarning("Cadastro duplicado - Alteracao. Nao será possível a alteracao desse registro pois ja existe um registro com o mesmo CPF, Categ. SEFIP e Cat. Func. com Matricula "	+;
						"diferente na base de Dados!! Favor verificar se os dados do Registro estão corretos!!","GP010VALPE02")
		_lRet := .F.
		Break
	EndIf
EndIf 

(_cAlias)->(DBCloseArea())

//Valida se tem outro funcionário com mesmo crachá
If !Empty(M->RA_CRACHA)
	_cAlias := GetNextAlias()
	BeginSql alias _cAlias
		SELECT RA_MAT, RA_NOME FROM %Table:SRA%
		WHERE D_E_L_E_T_ = ' '
		AND RA_CRACHA = %exp:AllTrim(M->RA_CRACHA)%
		AND RA_FILIAL = %xFilial:SRA%
		AND RA_MAT <> %exp:AllTrim(M->RA_MAT)%
	EndSql

	
	If !(_cAlias)->(Eof())
		FWAlertWarning("O crachá " + AllTrim(M->RA_CRACHA) + " já está em uso no funcionário " +  (_cAlias)->RA_MAT + " - " + (_cAlias)->RA_NOME+;
		 " Escolha outro crachá ou retire o vínculo já existente","GP010VALPE03")
		 _lRet := .F.
	 	(_cAlias)->(DBCloseArea())
		 Break
	EndIf
	(_cAlias)->(DBCloseArea())
EndIf

//Valida se tem outro funcionário com mesmo rfid
If !Empty(M->RA_I_CRACH)
	_cAlias := GetNextAlias()

	BeginSql alias _cAlias
		SELECT RA_MAT, RA_NOME FROM %Table:SRA%
		WHERE D_E_L_E_T_ = ' '
		AND RA_I_CRACH = %exp:AllTrim(M->RA_I_CRACH)%
		AND RA_FILIAL = %xFilial:SRA%
		AND RA_MAT <> %exp:AllTrim(M->RA_MAT)%
	EndSql

	If !(_cAlias)->(Eof())
		FWAlertWarning("O crachá " + AllTrim(M->RA_I_CRACH) + " já está em uso no funcionário " +  TEMP->RA_MAT + " - " + TEMP->RA_NOME +;
		 " Escolha outro crachá ou retire o vínculo já existente","GP010VALPE04")
		 _lRet := .F.
		 (_cAlias)->(DBCloseArea())
		 Break
	EndIf
	(_cAlias)->(DBCloseArea())
EndIf

Begin Transaction     

//===============================================================================================
// Verifica se o cadastro do funcionario nao possui nenhuma inconsistencia 
// detectada antes de realizar a integracao com o cadastro de clientes
//===============================================================================================
If _lRet
  _ltemp := ImportaFun()
	If !_ltemp
		FWAlertWarning("Não foi possível criar cadastro de cliente para o funcionário. Crie o cliente se necessário","GP010VALPE05")
	EndIf
EndIf

//================================================================================
//Exporta o funcionário para o cadastro de fornecedor do sistema
//================================================================================
If _lRet
   _ltemp := ImportFor()
   	If !_ltemp
		FWAlertWarning("Não foi possível criar cadastro de fornecedor para o funcionário. Crie o fornecedor se necessário","GP010VALPE06")
	EndIf
EndIf

If !_lRet
   Disarmtransaction()
   Break
EndIf

//=================================================================================
//Atualiza arquivo de crachas
//=================================================================================
//Zera vínculos a matricula atual 
DBSelectArea("ZGI")
ZGI->(DBSetOrder(2))
If _lRet .And. ZGI->(DBSeek(xFilial("ZGI")+M->RA_MAT))
	While cFilAnt == ZGI->ZGI_FILIAL .And. M->RA_MAT == ZGI->ZGI_MAT
	 	ZGI->(RecLock("ZGI",.F.))
	 	ZGI->ZGI_MAT := ""
	 	ZGI->ZGI_ENVISU := ""
	 	ZGI->(MSUnLock())
	 	ZGI->(DBSkip())
	 EndDo
EndIf

//Atualiza cracha com matricula atual
ZGI->(DBSetOrder(1))
If _lRet .And. !Empty(M->RA_CRACHA) .And. ZGI->(DBSeek(xFilial("ZGI")+M->RA_CRACHA))
	ZGI->(RecLock("ZGI",.F.))
 	ZGI->ZGI_MAT := M->RA_MAT
 	ZGI->ZGI_ENVISU := ""
 	ZGI->(MSUnLock())
ElseIf _lRet
	ZGI->(RecLock("ZGI",.T.))
	ZGI->ZGI_FILIAL := xFilial("ZGI")
 	ZGI->ZGI_MAT := M->RA_MAT
 	ZGI->ZGI_ENVISU := ""
 	ZGI->(MSUnLock())
EndIf

End Transaction     

End Sequence

FWRestArea(_aArea)

Return _lRet

/*
===============================================================================================================================
Programa----------: ImportaFun
Autor-------------: Fabiano Dias
Data da Criacao---: 07/07/2010
Descrição---------: Função que importa os dados de funcionários para o cadastro de Clientes
Parametros--------: Nenhum
Retorno-----------: lRet - Indica se o cadastro foi importado ou não.
===============================================================================================================================
*/
Static Function ImportaFun() As Logical

Local _aArea		:= FWGetArea() As Array
Local _lRetorno		:= .T. As Logical
Local _aCadCliente	:= {} As Array
Local _lMVCSA1      := SuperGetMV("MV_MVCSA1",.F.,.F.)  As Logical// Parammetro para habilitar execução do ExecAuto do novo CRMA980 
Local _cErro        := "" As Character

Private nSaveSX8	:= ""
Private lMsErroAuto	:= .F.
Private lMsHelpAuto	:= .T.

//Verifica se esta realizando a inclusao de um funcionario
_aCadCliente := vldImport( M->RA_CIC )

If Inclui .Or. (Altera .And. _aCadCliente[1,1] .And.  AllTrim(_cCPFAnterior) == AllTrim(M->RA_CIC) )
		
	//Verifica se o funcionario ja possui cadastro realizado no cadastro de clientes
	_aCadCliente := vldImport( M->RA_CIC )
	
	If _aCadCliente[1,1]
		//Recupera os dados do funcionário para inclusão do cliente
		_aCliente := DadosImpor( 1 , "" , "" )
		
		lMsErroAuto := .F.
		
		//Guarda e recupera posição do SRA pois o execauto pode desposicionar
		_nposSRA := SRA->(Recno())
		_aCliente:=U_AcertaDados("SA1",_aCliente)//por causado MVC
		// Variavel que controla numeracao
		nSaveSX8 := GetSx8Len()
        If _lMVCSA1
            MSExecAuto( {|x,y,z| CRMA980(x,y,z) } , _aCliente , 3 , )
		Else
            MSExecAuto( {|x,y,z| mata030(x,y,z) } , _aCliente ,, 3 )
        EndIf
        SRA->(DBGoTo(_nposSRA))
		
		If lMsErroAuto
			If ( __lSX8 )
				RollBackSx8()
			EndIf

			_cErro := "O cadastro do Funcionário: " + AllTrim(M->RA_NOME) + " possui alguns campos obrigatorios para realizar "
			_cErro += "a importacao para o cadastro de Clientes que não foram preenchidos. "
			_cErro += "Desta forma não será gerada a sua importação, favor checar novamente o cadastro deste funcionario, ao "
			_cErro += "persistir o erro favor informar a área de TI/ERP."

			If FWIsInCallStack("U_AGPE010")	
			    _cErroAGPE010 := _cErro 
				_cErroAGPE010 += " MSExecAuto: [ "+MostraErro(Upper(GetSrvProfString("STARTPATH","")),"AGPE010.LOG")+" ]"
			Else			
				MostraErro()
				
				FWAlertWarning(_cErro,"GP010VALPE07")
			EndIf

			_lRetorno := .F.
		Else
			If __lSX8
				While ( GetSX8Len() > nSaveSX8 )
					ConfirmSX8()
				EndDo
			EndIf
		EndIf
	Else
		FWAlertWarning(	"O Funcionário: " + AllTrim(M->RA_NOME) + " ja possui um cadastro de cliente realizado. "+;
						"Desta forma não será gerada a sua importação.","GP010VALPE08")
	EndIf
	
//Verifica se esta realizando a alteracao de um funcionario
ElseIf Altera
	_aCadCliente := vldImport( _cCPFAnterior )

	// Se o funcionario já foi cadastrado como cliente é possivel realizar a alteracao
	If !_aCadCliente[1,1]
		
		DBSelectArea("SA1")
		SA1->(DBSetOrder(1))
		If SA1->(DBSeek(xFilial("SA1") + _aCadCliente[1,2] + _aCadCliente[1,3]))
		    _aCliente := DadosImpor( 2 , _aCadCliente[1,2] , _aCadCliente[1,3] )
		
			//Guarda e recupera posição do SRA pois o execauto pode desposicionar
			_nposSRA := SRA->(Recno())
		    _aCliente:=U_AcertaDados("SA1",_aCliente)//por causado MVC
			lMsErroAuto := .F.
			
			SA1->(RecLock("SA1",.F.))
			If _lMVCSA1
			    MSExecAuto( {|x,y,z| CRMA980(x,y,z)} , _aCliente , 4 , )
            Else
                MSExecAuto( {|x,y| MATA030(x,y)} , _aCliente , 4 )
            EndIf
            SA1->(MSUnLock())
			SRA->(DBGoTo(_nposSRA))
		EndIf

		_cErro := "O cadastro do(a) Funcionário(a): " + AllTrim(M->RA_NOME) + " possui alguns campos obrigatorios para "
		_cErro += "realizar a importacao para o cadastro de clientes que nao foram preenchidos. "
		_cErro += "Desta forma não será gerada a sua importação, favor checar novamente o cadastro deste(a) funcionario(a), "
    	_cErro +=  "ao persistir o erro favor contactar o depto de informática."

		If lMsErroAuto
			If FWIsInCallStack("U_AGPE010")	
			    _cErroAGPE010 := _cErro 
				_cErroAGPE010 += " MSExecAuto: [ "+MostraErro(Upper(GetSrvProfString("STARTPATH","")),"AGPE010.LOG")+" ]"
			Else			
				MostraErro()
				
				FWAlertWarning(_cErro,"GP010VALPE07")
			EndIf

			_lRetorno := .F.
	    EndIf
	EndIf
EndIf
	                                  
FWRestArea(_aArea)

Return _lRetorno

/*
===============================================================================================================================
Programa----------: vldImport
Autor-------------: Fabiano Dias
Data da Criacao---: 07/07/2010
Descrição---------: Função que valida se já existe cadastro de cliente para o funcionário que está sendo inserido/alterado
Parametros--------: Nenhum
Retorno-----------: _aRet - Retorna os dados referentes ao cadastro, ou indicação de que o mesmo não existe
===============================================================================================================================
*/
Static Function vldImport(_cCPF As Character) As Array

Local _nCntRec	:= 0 As Numeric
Local _cAlias	:= GetNextAlias() As Character         
Local _aRet		:= {} As Array

BeginSql alias _cAlias
	SELECT A1_COD, A1_LOJA FROM %Table:SA1%
	WHERE D_E_L_E_T_ = ' '
	AND A1_Filial = %xFilial:SA1%
	AND A1_MSBLQL = '2'
	AND A1_CGC = %exp:_cCPF%
EndSql

Count To _nCntRec
(_cAlias)->(DBGoTop())

If _nCntRec > 0
	aAdd(_aRet,{.F.,(_cAlias)->A1_COD,(_cAlias)->A1_LOJA})
Else
 	aAdd(_aRet,{.T.,""				,""			})
EndIf

(_cAlias)->(DBCloseArea())

Return _aRet

/*
===============================================================================================================================
Programa----------: DadosImpor
Autor-------------: Fabiano Dias
Data da Criacao---: 07/07/2010
Descrição---------: Função que insere os dados da importação dos funcionários para o cadastro de clientes de acordo com a
------------------: operação (inclusão/alteração)
Parametros--------: _nTipo   = 1 - Inclusão / 2 - Alteração
------------------: _cCodCli = Código do Cliente
------------------: _cLojCLi = Loja do Cliente
Retorno-----------: _aCliente - Retorna os dados referentes ao cadastro
===============================================================================================================================
*/
Static Function DadosImpor(_nTipo As Numeric,_cCodCli As Character,_cLojaCli As Character) As Array
                         
Local _aCliente		:= {} As Array
Local _cCodVend		:= "000156" As Character
Local _cDDD			:= "" As Character
Local _cTel			:= "" As Character
Local _cEmail		:= AllTrim(M->RA_EMAIL) As Character
Local _cCContabil	:= "" As Character
Local _cRisco		:= "" As Character
Local _nLimite		:= 0 As Numeric
Local _dLimite		:= SToD("20010101") As Date

//================================================================================
// Valida de qual filial esta sendo executado o cadastro do 
// funcionario para preenchimento do campo A1_CONTA (HELP 583).
//================================================================================
Do Case
	Case cFilAnt $ '01/02/03/04/05/06'
		_cCContabil := "1102069998"
	Case cFilAnt $ '10/11/12/13/14/15/16/17/18/19/1A/1B/1C' 
		_cCContabil := "1102069999"
	Case cFilAnt $ '20/21/22'
		_cCContabil := "1102069993"
	Case cFilAnt == '30'
		_cCContabil := "1102064806"
	Case cFilAnt == '90'
		_cCContabil := "1102069996"
	Case cFilAnt == '91' 
		_cCContabil := "1102069992"
	OtherWise			
		_cCContabil := " "
EndCase

//Verifica se o funcionario possui telefone
If !Empty(M->RA_TELEFON)
	_cDDD	:= "0" + SubStr(M->RA_TELEFON,1,2)
    _cTel	:= SubStr(M->RA_TELEFON,3,8)
Else
	_cDDD :="999"
	_cTel :="99999999"
EndIf          
 
aAdd(_aCliente,{"A1_FILIAL",xFilial("SA1"),Nil})

//Carrega parâmetros de limite de crédito
_cRisco 	:= 	SuperGetMV("IT_RISCOFUN",.F.,"B")
_nLimite 	:=	SuperGetMV("IT_LIMFUNC" ,.F.,150)
_dLimite 	:=	SuperGetMV("IT_VENCLIMFUNC",.F.,SToD("20491231"))

// Alteracao
If _nTipo == 2
	aAdd(_aCliente,{"A1_COD"		, _cCodCli				, Nil }) // CODIGO DO CLIENTES
	aAdd(_aCliente,{"A1_LOJA"		, _cLojaCli				, Nil }) // LOJA DO CLENTE
EndIf

aAdd(_aCliente,{"A1_NOME"		, Left(M->RA_NOMECMP,Len(SA1->A1_NOME))	, Nil }) // NOME
aAdd(_aCliente,{"A1_PESSOA"		, "F"						, Nil }) // PESSOA FISICA OU JURIDICA
aAdd(_aCliente,{"A1_CGC"		, M->RA_CIC					, Nil }) // CGC
aAdd(_aCliente,{"A1_NREDUZ"		, Left(M->RA_NOME,Len(SA1->A1_NREDUZ))		, Nil }) // NOME REDUZIDO
aAdd(_aCliente,{"A1_TIPO"		, "F"						, Nil }) // TIPO DE CLIENTE
aAdd(_aCliente,{"A1_EST"		, M->RA_ESTADO				, Nil }) // ESTADO
aAdd(_aCliente,{"A1_COD_MUN"	, M->RA_CODMUN				, Nil }) // COD.MUNICIPIO
aAdd(_aCliente,{"A1_CEP"		, M->RA_CEP					, Nil }) // CEP
aAdd(_aCliente,{"A1_END"		, AllTrim(M->RA_ENDEREC)+", "+AllTrim(M->RA_LOGRNUM), Nil }) // ENDEREÇO   // aAdd( _aCliente , { "A1_END", M->RA_ENDEREC	, Nil }) // ENDEREÇO
aAdd(_aCliente,{"A1_BAIRRO"		, M->RA_BAIRRO				, Nil }) // BAIRRO
aAdd(_aCliente,{"A1_DDD"		, _cDDD						, Nil }) // DDD DO TELEFONE
aAdd(_aCliente,{"A1_TEL"		, _cTel						, Nil }) // NUMERO DO TELEFONE
aAdd(_aCliente,{"A1_PAIS"		, "105"						, Nil }) // PAIS
aAdd(_aCliente,{"A1_CODPAIS"	, "01058"					, Nil }) // PAIS BACEN
aAdd(_aCliente,{"A1_ESTC"		, M->RA_ESTADO				, Nil }) // ESTADO COBRANCA
aAdd(_aCliente,{"A1_I_CMUNC"	, M->RA_CODMUN				, Nil }) // COD.MUNICIPIO COBRANCA
aAdd(_aCliente,{"A1_CEPC"		, M->RA_CEP					, Nil }) // CEP COBRANCA
aAdd(_aCliente,{"A1_ENDCOB "	, AllTrim(M->RA_ENDEREC)+", "+AllTrim(M->RA_LOGRNUM), Nil }) // ENDERECO COBRANCA   // aAdd( _aCliente , { "A1_ENDCOB "	, M->RA_ENDEREC	, Nil }) // ENDERECO COBRANCA
aAdd(_aCliente,{"A1_BAIRROC"	, M->RA_BAIRRO				, Nil }) // BAIRRO COBRANCA
aAdd(_aCliente,{"A1_INSCR"		, ""						, Nil }) // INSCRICAO ESTADUAL
aAdd(_aCliente,{"A1_I_GRCLI"	, "39"						, Nil }) // GRUPO CLIENTE // "11" // SEGUIMENTO
aAdd(_aCliente,{"A1_NATUREZ"	, "111001"					, Nil }) // NATUREZA
aAdd(_aCliente,{"A1_VEND"		, _cCodVend					, Nil }) // CODIGO DO VENDEDOR
aAdd(_aCliente,{"A1_GRPVEN"		, "999999"					, Nil }) // GRUPO DE VENDAS
aAdd(_aCliente,{"A1_RISCO"		, _cRisco					, Nil }) // RISCO CLIENTE
If _nTipo == 1//INCLUSAO
   aAdd(_aCliente,{"A1_LC"		, _nLimite					, Nil }) // VALOR DO LIMITE
Else // ALTERAÇÃO 
   If SA1->A1_LC < _nLimite 
      aAdd(_aCliente,{"A1_LC"		, _nLimite					, Nil }) // VALOR DO LIMITE
   EndIf
EndIf
aAdd(_aCliente,{"A1_VENCLC"		, _dLimite					, Nil }) // DATA DE VENCIMENTO DO LIMITE
aAdd(_aCliente,{"A1_EMAIL"		, _cEmail					, Nil }) // EMAIL
aAdd(_aCliente,{"A1_CONTA"		, _cCContabil				, Nil }) // Conta Contabil
aAdd(_aCliente,{"A1_COND"		, "001"						, Nil }) // CONDICAO DE PAGTO INCLUSÃO 
aAdd(_aCliente,{"A1_CONTRIB"	, "2"						, Nil }) // Contribuinte do ICMS
aAdd(_aCliente,{"A1_SIMPNAC"	, "2"						, Nil }) // Opt Simples Nacional
aAdd(_aCliente,{"A1_CLIFUN"		, "1"						, Nil }) // Funcionário 
aAdd(_aCliente,{"A1_COMPLEM"	, M->RA_COMPLEM				, Nil }) // COMPLEMENTO DO ENDEREÇO.

Return _aCliente

/*
===============================================================================================================================
Programa----------: ImportFor
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 20/03/2017
Descrição---------: Função que importa os dados de funcionários para o cadastro de fornecedores
Parametros--------: Nenhum
Retorno-----------: lRet - Indica se o cadastro foi importado ou não.
===============================================================================================================================
*/
Static Function ImportFor As Logical

Local _aArea		:= FWGetArea() As Array
Local _lRetorno		:= .T. As Logical
Local _aCadFornec	:= {} As Array

Private nSaveSX8	:= "" As Numeric
Private lMsErroAuto	:= .F. As Logical
Private lMsHelpAuto	:= .T. As Logical

//Verifica se o funcionario ja possui cadastro realizado no cadastro de fornecedor
_aCadFornec := vldFornec( _cCPFAnterior )
SA2->(DBSetOrder(1))

If _aCadFornec[1,1]
	//Recupera os dados do funcionário para inclusão do fornecedor
	_aFornec := DadosForn( 1 , "" , "" )
ElseIf SA2->(DBSeek(xFilial("SA2")+_aCadFornec[1,2]+_aCadFornec[1,3]))
	//Recupera os dados do funcionário para alteração do fornecedor
	_aFornec := DadosForn( 2 , _aCadFornec[1,2] , _aCadFornec[1,3] )	
EndIf
	
FWRestArea(_aArea)

Return _lRetorno

/*
===============================================================================================================================
Programa----------: vldFornec
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 20/03/2017
Descrição---------: Função que valida se já existe cadastro de fornecedor para o funcionário que está sendo inserido/alterado
Parametros--------: Nenhum
Retorno-----------: _aRet - Retorna os dados referentes ao cadastro, ou indicação de que o mesmo não existe
===============================================================================================================================
*/
Static Function vldFornec(_cCPF As Character) As Array

Local _nCntRec	:= 0 As Numeric
Local _cAlias	:= GetNextAlias() As Character         
Local _aRet		:= {} As Array

BeginSql alias _cAlias
	SELECT A2_COD, A2_LOJA FROM %Table:SA2%
	WHERE D_E_L_E_T_ = ' '
	AND A2_Filial = %xFilial:SA2%
	AND A2_CGC = %exp:_cCPF%
EndSql

Count To _nCntRec
(_cAlias)->(DBGoTop())

If _nCntRec > 0
	aAdd(_aRet,{.F.,(_cAlias)->A2_COD,(_cAlias)->A2_LOJA})
Else
 	aAdd(_aRet,{.T.,""				, ""			})
EndIf

(_cAlias)->(DBCloseArea())

Return _aRet 

/*
===============================================================================================================================
Programa----------: DadosForn
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 20/03/2017
Descrição---------: Função que insere os dados da importação dos funcionários para o cadastro de fornecedores de acordo com a
------------------: operação (inclusão/alteração)
Parametros--------: _nTipo   = 1 - Inclusão / 2 - Alteração
------------------: _cCodCli = Código do Cliente
------------------: _cLojCLi = Loja do Cliente
Retorno-----------: _aCliente - Retorna os dados referentes ao cadastro
===============================================================================================================================
*/
Static Function DadosForn(_nTipo As Numeric,_cCodFor As Character,_cLojaFor As Character) As Array

Local _aFornec	:= {} As Array
Local aVetor 	:= {} As Array

Default _cCodFor	:= U_ACOM005("J", "F", _cCPFAnterior)
Default _cLojaFor	:= "0001"

If Empty(_cCodFor)
	_cCodFor := U_ACOM005("J", "F", _cCPFAnterior)
EndIf

If Empty(_cLojaFor)
	_cLojaFor	:= "0001"
EndIf

//Monta array do execauto
aAdd(aVetor,{"A2_I_CLASS"	, "J"												, nil } )
aAdd(aVetor,{"A2_TIPO"		, "F"											 	, nil } )
aAdd(aVetor,{"A2_CGC"		, M->RA_CIC											, nil } )
aAdd(aVetor,{"A2_COD"		, _cCodFor											, nil } )
aAdd(aVetor,{"A2_LOJA"		, _cLojaFor											, nil } )
aAdd(aVetor,{"A2_NOME"		, AllTrim(M->RA_NOME)								, nil } ) 
aAdd(aVetor,{"A2_NREDUZ"		, SubStr(AllTrim(M->RA_NOME),1,20)					, nil } ) 
aAdd(aVetor,{"A2_EST"		, AllTrim(M->RA_ESTADO)								, nil } )
aAdd(aVetor,{"A2_COD_MUN"	, AllTrim(M->RA_CODMUN)								, nil } )
aAdd(aVetor,{"A2_MUN"	     ,AllTrim(Posicione('CC2',1,xFilial('CC2')+M->RA_ESTADO+M->RA_CODMUN,'CC2_MUN'))   , nil } )                                                           
aAdd(aVetor,{"A2_CEP"		, AllTrim(M->RA_CEP)								, nil } )
aAdd(aVetor,{"A2_END"		, AllTrim(M->RA_ENDEREC)+", "+AllTrim(M->RA_LOGRNUM), nil } )
aAdd(aVetor,{"A2_BAIRRO"		, AllTrim(M->RA_BAIRRO)								, nil } )
aAdd(aVetor,{"A2_DDD"		, AllTrim(M->RA_DDDFONE)							, nil } )
aAdd(aVetor,{"A2_TEL"		, AllTrim(M->RA_TELEFON)							, nil } )
If !Empty(M->RA_EMAIL)
	aAdd(aVetor,{"A2_EMAIL"		,AllTrim(M->RA_EMAIL)								, nil } )
EndIf
If _nTipo = 1//Só na Inclusão
   aAdd(aVetor,{"A2_BANCO"		, SubStr(M->RA_BCDEPSA,1,3)							, nil } )
   aAdd(aVetor,{"A2_AGENCIA"	, SubStr(M->RA_BCDEPSA,4,5)							, nil } )
   aAdd(aVetor,{"A2_NUMCON"		, SubStr(M->RA_CTDEPSA,1,10)						, nil } )
EndIf
aAdd(aVetor,{"A2_PAIS"		, '105'		 										, nil } )
aAdd(aVetor,{"A2_CODPAIS"	, '01058'	 										, nil } )
aAdd(aVetor,{"A2_TRIBFAV"	, '2'	 											, nil } )  
aAdd(aVetor,{"A2_COMPLEM"	, M->RA_COMPLEM										, nil } ) // COMPLEMENTO DO ENDEREÇO

MSExecAuto( {|x,y| Mata020(x,y) } , aVetor , IIf(_nTipo==2,4,3) )
	
If lMSErroAuto
	DisarmTransaction()
	If ( __lSx8 )
		RollBackSx8()
	EndIf 

	If FWIsInCallStack("U_AGPE010")	
	    _cErroAGPE010 := "Falha na Inclusão do Fornecedor " 
		_cErroAGPE010 += " MSExecAuto: [ "+MostraErro(Upper(GetSrvProfString("STARTPATH","")),"AGPE010.LOG")+" ]"
	Else
		Mostraerro()
	EndIf

	_lRet:= .F.    
Else        
	DBCommit()
	If ( __lSX8 )
		ConfirmSX8()
	EndIf				
EndIf

M->RA_I_F := _cCodFor

Return _aFornec

/*
===============================================================================================================================
Programa--------: AcertaDados
Autor-----------: Alex Wallauer
Data da Criacao-: 13/08/2021
Descrição-------: Acerta os dados para o tamanho do campo de destino por causado MVC
Parametros------: cAlias do MS EXECAUTO() ,_aDados: Array do MS EXECAUTO()
Retorno---------:_aDados
===============================================================================================================================
*/
User Function AcertaDados(cAlias As Character,_aDados As Array) As Array

Local _nX		:= 0 As Numeric
Local _cCampo	:= '' As Character
Local aRet 		:= {}

For _nX := 1 To Len(_aDados)
    If ValType(_aDados[_nX,2]) = "C"
        aRet := TamSX3(_aDados[_nX,1])
        If aRet[3] <> "M"
            _cCampo:=(cAlias)->&(_aDados[_nX,1])
            _aDados[_nX,2]:=Left(_aDados[_nX,2],Len(_cCampo))
        EndIf
	EndIf
Next _nX

Return _aDados
