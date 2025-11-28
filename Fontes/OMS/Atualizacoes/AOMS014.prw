/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     | 20/10/2023 | Chamado 45189. Ajustar rotina de efetivação para validar JSons retornados vazios da CISP. 
Igor Melgaço  | 19/06/2024 | Chamado 47534. Ajuste para exibição da descrição do CNAE. 
Lucas Borges  | 22/04/2025 | Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
Lucas Borges  | 23/07/2025 | Chamado 51340. Ajustar função para validação de ambiente de teste
===============================================================================================================================
Analista - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
==========================================================================================================================================================================================================
Lucas    - Alex Wallauer - 24/09/24 - 24/09/24 - 48465   - Removido warnings do code analisys.
Antonio  - Igor Melgaço  - 26/12/24 - 27/12/24 - 49451   - Ajuste para correção de erro.
Jerry    - Julio Paz     - 11/04/24 - 11/04/25 - 44503   - Alterar a rotina para gravar o Subsegmento (A1_I_SUBCO = ZX_SUB_COD). 
Andre    - Alex Wallauer - 09/06/25 - 09/06/25 - 50958   - Ajuste no tratamento da descrição do corpo do e-mail.
Antonio  - Julio Paz     - 17/06/25 - 27/06/25 - 50278   - Criação de Campo e Inclusão de validações para determinar usuários que podem aprovar o prospect com base nos limetes de crédito do Propspect.
==========================================================================================================================================================================================================
*/

#Include "TOTVS.ch"
#Include "AP5mail.ch"
#Include "fwmvcdef.ch"

/*
===============================================================================================================================
Programa----------: AOMS014
Autor-------------: Erich Buttner
Data da Criacao---: 04/03/2013
Descrição---------: Rotina de análise e efetivação de Prospect cadastrado pelo Portal
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS014()

Private aRotina		:= {}
Private ccadastro   := "Prospect"
Private _lConsdBrk  := .T.  // Quando True considera os valores de limite de crédito do Broker. Quando False considera o limite de crédito do cadastro de clientes.

aAdd( aRotina , { "Efetivar"	  , "U_AOMS014T"	, 0 , 4 } )
aAdd( aRotina , { "Alterar"		  , "U_AOMS014Y" 	, 0 , 4 } )
aAdd( aRotina , { "Excluir"		  , "U_AOMS014R" 	, 0 , 4 } )  
aAdd( aRotina , { "At. Cisp"	  , "U_AOMS014K" 	, 0 , 4 } ) 
aAdd( aRotina , { "An. Cred"	  , "U_AOMS014C" 	, 0 , 4 } )
aAdd( aRotina , { "Enviar E-mail" , "U_AOMS014G" 	, 0 , 4 } )
aAdd( aRotina , { "Legenda"       , "U_AOMS014F" 	, 0 , 4 } )

SZX->( DBSetOrder(1) )
SZX->( DBGoTop() )

oBrw := FWMBrowse():New()
oBrw:SetAlias( "SZX" )
oBrw:SetDescription( "Prospect" )
oBrw:SetFilterDefault( "SZX->ZX_STATUS = 'L'" )
//adiciona legenda
oBrw:AddLegend( "ZX_I_ENVML == 'S'" , "BLUE", "E-mail Enviado." )
oBrw:AddLegend( "!Empty(ZX_I_GRPVE) .And. !Empty(ZX_I_RISCO) .And. !Empty(ZX_I_ACRED)" , "GREEN", "Análise efetuada" )
oBrw:AddLegend( "Empty(ZX_I_GRPVE) .Or. Empty(ZX_I_RISCO) .Or. Empty(ZX_I_ACRED)" , "RED" , "Falta grupo de vendas,risco de crédito e observação de análise" )
oBrw:Activate()

Return(.T.)

/*
===============================================================================================================================
Programa----------: AOMS014E
Autor-------------: Erich Buttner
Data da Criacao---: 04/03/2013
Descrição---------: Efetivação de Cadastro de Prospect (Novo Cliente)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS014E() As Logical

Local _aVetor As Array
Local _aCodAux As Array
Local _cCodAux As Character 
Local _nCodAux As Numeric
Local nNRelmp As Numeric
Local _cQuery As Character
Local _cAlias As Character

Local _cNome As Character
Local _cNReduz As Character
Local _cEst	As Character
Local _cEnd	As Character
Local _cBairro As Character
Local _cContato	As Character
Local _cInscr As Character
Local _cComplem As Character
Local _cCarGc As Character
Local _cBoleto As Character
Local _cVendGen As Character
Local _cGrpGen As Character
Local _lMVCSA1 As Logical
Local _cUfMVA As Character
Local _cTRIBMVA As Character
Local _nLimeteAp As Numeric

Private lMsErroAuto	As Logical

_aVetor 		:= {}
_aCodAux		:= {}
_cCodAux		:= ""
_nCodAux		:= 0
nNRelmp			:= 0
_cQuery			:= ""
_cAlias			:= ""

_cNome 			:= ""
_cNReduz		:= ""
_cEst			:= ""
_cEnd			:= ""
_cBairro		:= ""
_cContato		:= ""
_cInscr		  := ""
_cComplem	  := ""
_cCarGc		  := ""
_cBoleto      := SZX->ZX_I_IBOLE
_cVendGen     := U_ITGetMV("IT_VENDGEN","000156")
_cGrpGen      := U_ITGetMV("IT_GRPGEN","11")
_lMVCSA1      := U_ItGetMv( "MV_MVCSA1" , .F. )
_cUfMVA       := U_ITGetMV("IT_UFSMVA","PR")
_cTRIBMVA     := U_ITGetMV("IT_TRIBMVA","023")
lMsErroAuto   := .F.

//================================================================ 
// Verifica se o usuário tem permissão para efetivar o prospect.
//================================================================
_nLimeteAp :=  Posicione("ZZL",3,xFilial("ZZL")+AllTrim(__cUserId),"ZZL_VLMAXP") // ZZL_FILIAL+ZZL_CODUSU
If ValType(_nLimeteAp) <> "N"
   _nLimeteAp := 0
EndIf 

If SZX->ZX_I_LC > _nLimeteAp  // Sugestão de Limite de Crédito 
   U_ITMsg("O Valor do limite de crédito deste cliente: " + AllTrim(Str(SZX->ZX_I_LC,14,2)) + ", é superior ao limite permitido para este usuário aprovar: " + AllTrim(Str(_nLimeteAp,14,2))+".","Atenção","",1)
   Return
EndIf 
 
//================================================================
// Valida Simples Nacional.
//================================================================
If Empty(SZX->ZX_SIMPNAC)

	U_ITMsg("É obrigatorio selecionar se o cliente é Simples Nacional","Atenção","Selecione se o cliente é Simples Nacional",1)
	Return
	
EndIf

If Empty(SZX->ZX_CONTRIB)

	U_ITMsg("É obrigatorio selecionar se o cliente é Contribuinte ICMS","Atenção","Selecione se o cliente é Contribuinte ICMS",1)
	Return
	
EndIf

//Valida se cliente está ativo no Sintegra quando teve consulta pela Cisp
If !Empty(AllTrim(SZX->ZX_SITST))

	_csitmaior := Upper(AllTrim(SZX->ZX_SITST))
	If 	!(_csitmaior == "HABILITADO" .Or. _csitmaior == "HABILITADA" .Or. _csitmaior == "ATIVO" .Or. _csitmaior == "ATIVA" .Or. _csitmaior == "ATIVO - HABILITADO"  .Or. _csitmaior == "HABILITADO - ATIVO")
	
		U_ITMsg("Cliente com restrição no cadastro do Sintegra","Atenção","Efetivação não será realizada",1)
		Return
		
	EndIf

EndIf


//Valida se cliente está ativo no Sintegra quando teve consulta pela Cisp
If !Empty(AllTrim(SZX->ZX_I_SITRF))

	_csitmaior := AllTrim(SZX->ZX_I_SITRF)
	If 	!(_csitmaior == "HABILITADO" .Or. _csitmaior == "HABILITADA" .Or. _csitmaior == "ATIVO" .Or. _csitmaior == "ATIVA" .Or. _csitmaior == AllTrim(SubStr("ATIVO - HABILITADO",1,10))  .Or. _csitmaior == AllTrim(SubStr("HABILITADO - ATIVO",1,10))) // O campo ZX_I_SITRF tem um tamanho de 10 posições.
	
		U_ITMsg("Cliente com restrição no cadastro da Receita","Atenção","Efetivação não será realizada",1)
		Return
		
	EndIf

EndIf


DBSelectArea('SA3')
SA3->( DBSetOrder(1) )
If SA3->( DBSeek( xFilial('SA3') + SZX->ZX_VEND ) )
	
	If SA3->A3_I_TIPV <> 'V'
	
	
		U_ITMsg('O cadastro atual não pode ser efetivado pois o vendedor amarrado ao Cliente não está classificado como Vendedor!',"Validação  de vendedor",;
				'Verifique os dados informados e/ou o cadastro do Vendedor no Sistema antes de solicitar a efetivação.',1)
			
		Return

	EndIf
	
	If SA3->A3_MSBLQL == '1'
	
		U_ITMsg('O cadastro atual não pode ser efetivado pois o vendedor amarrado ao Cliente está bloqueado no sistema!',"Validação  de vendedor",;
				'Verifique os dados informados e/ou o cadastro do Vendedor no Sistema antes de solicitar a efetivação.',1)
				
		Return

	EndIf
	
Else

	U_ITMsg('O cadastro atual não pode ser efetivado pois o vendedor amarrado ao Cliente não é válido no cadastro do Sistema!',"Validação  de vendedor",;
				'Verifique os dados informados e/ou o cadastro do Vendedor no Sistema antes de solicitar a efetivação.',1)

	
	Return
	
EndIf


//Valida se cliente está pertence ao grupo 11 o vendedor tem que ser genérico
If !Empty(AllTrim(_cGrpGen)) .And. !Empty(AllTrim(_cVendGen)) 
	
	If SZX->ZX_GRCLI $ _cGrpGen .And. !(SZX->ZX_VEND $ _cVendGen)
		
		U_ITMsg("A efetivação não será realizada!"+Chr(13)+Chr(10)+"Para este grupo de clientes "+SZX->ZX_GRCLI+" só é permito vincular os vendedores genéricos: "+_cVendGen,"Atenção","Altere o vendedor para um que seja genérico conforme informado.",1)

		Return

	EndIf

EndIf


//Validação da inscrição estadual
If AllTrim(SZX->ZX_INSCR) != "ISENTO"

	_cInscr		:= U_AOMS014N(SZX->ZX_INSCR)

Else

	_cInscr     := "ISENTO"

EndIf

M->A1_EST   := U_AOMS014S(SZX->ZX_EST)

//Nova regra para composição do Campo de IE da UF de MG, que deve conter sempre 13 caracteres

If M->A1_EST == 'MG'
	_cInscr := AllTrim(_cInscr)
    _cInscr := PadL(_cInscr, 13, '0')
EndIf

M->A1_INSCR := _cInscr

If !(IE(M->A1_INSCR,M->A1_EST) .And. A030VldUCod()) .Or. Empty(_cInscr)

  U_ITMsg("Falha na validação da inscrição estadual!","Validação de inscrição estadual","Verifique a inscrição estadual no sintegra e digite somente os números ou ISENTO",1)
  
  Return
  
EndIf                                                                                  

//===============================================================================================
// ABRE CONTROLE DE TRANSACAO
//===============================================================================================
BeginTran()

Begin Sequence

DBSelectArea("CC2")
CC2->( DBSetOrder(1) )
CC2->( DBSeek( xFilial("CC2") + SZX->ZX_EST + SZX->ZX_CODMUN ) )

DBSelectArea("SA1")
SA1->( DBSetOrder(3) )
If SA1->( DBSeek( xFilial("SA1") + SZX->ZX_CGC ) )

	U_ITMsg(	"O CPF/CNPJ informado já existe no cadastro de clientes com o Código/Loja: ["+ SA1->A1_COD +"/"+ SA1->A1_LOJA +"]", "Validação de CNPJ"	,;
					"Não é permitido cadastrar dois Clientes com o mesmo CPF/CNPJ, verifique os cadastros antes de efetivar o Prospect.",1	 )
	
	nNRelmp := 0

Else
	
	_cQuery := " SELECT DISTINCT "
	_cQuery += "     A1_COD     ,"
	_cQuery += "     A1_MSBLQL   "
	_cQuery += " FROM  "+ RETSQLNAME('SA1') +" SA1 "
	_cQuery += " WHERE "+ RETSQLCOND('SA1')
	_cQuery += " AND A1_CGC     LIKE '"+ SubStr( SZX->ZX_CGC , 1 , 8 ) +"%' "
	_cQuery += " ORDER BY A1_COD "
	
	_cAlias := GetNextAlias()
	
	MPSysOpenQuery( _cQuery , _cAlias ) 
	
	_cCodAux := ""
	_nCodAux := 0
	
	DBSelectArea(_cAlias)
	(_cAlias)->( DBGoTop() )
	While (_cAlias)->( !Eof() )
	
		aAdd( _aCodAux , { (_cAlias)->A1_COD , IIf( (_cAlias)->A1_MSBLQL == '1' , 'Bloqueado' , 'Ativo' ) } )
		
		If _cCodAux <> (_cAlias)->A1_COD
			_cCodAux := (_cAlias)->A1_COD
			_nCodAux++
		EndIf
		
		(_cAlias)->( DBSkip() )
	EndDo
	
	(_cAlias)->( DBCloseArea() )
	
	If _nCodAux > 1
		
		U_ITMsg( 'Existe mais um código de cliente cadastrado para esse CNPJ no sistema. Verifique o código correto e selecione para continuar com a efetivação!' , 'Atenção!' ,,1)
		_cCodAux := U_ITListBox( 'Códigos de cliente encontrados para o CNPJ' , {'Código','Status'} , _aCodAux , .F. , 3 , 'Selecione o código a ser utilizado na efetivação:' ,,{100,100}, 1 )
		
		If Empty( _cCodAux )
			U_ITMsg(  'Operação cancelada pelo usuário!' ,,,1 )
			DisarmTransaction()
			Break // Return

		EndIf
	EndIf

	_cNome 		:= SZX->ZX_NOME
	_cNReduz	:= SZX->ZX_NREDUZ
	_cEst		:= SZX->ZX_EST
	_cEnd		:= SZX->ZX_END
	_cBairro	:= SZX->ZX_BAIRRO
	_cContato	:= SZX->ZX_CONTATO
	_cComplem	:= SZX->ZX_COMPLEM
	_cCarGc		:= SZX->ZX_CARGC

	_cBairro := StrTran(_cBairro,"º","") // Estes caracteres especiais estavam impedindo a criação do registro no Cadastro de clientes. No MSEXECAUTO. 
	_cBairro := StrTran(_cBairro,"ª","") // Estes caracteres especiais estavam impedindo a criação do registro no Cadastro de clientes. No MSEXECAUTO. 
	
	If !(U_CRMA980VCP(@_cNome    ,"ZX_NOME"))
		Break // Return
	EndIf
	If !(U_CRMA980VCP(@_cNReduz  ,"ZX_NREDUZ"))
		Break // Return
	EndIf
	If !(U_CRMA980VCP(@_cEst     ,"ZX_EST"))
		Break // Return
	EndIf
	If !(U_CRMA980VCP(@_cEnd     ,"ZX_END"))
		Break // Return
	EndIf
	If !(U_CRMA980VCP(@_cBairro  ,"ZX_BAIRRO"))
		Break // Return
	EndIf
	If !(U_CRMA980VCP(@_cContato ,"ZX_CONTATO"))
		Break // Return
	EndIf
	If !(U_CRMA980VCP(@_cComplem ,"ZX_COMPLEM"))
		Break // Return
	EndIf
	If !(U_CRMA980VCP(@_cCarGc   ,"ZX_CARGC"))
		Break // Return
	EndIf

	//Validação de cadastro Chep
	If Len(AllTrim(SZX->ZX_I_CCHEP)) == 10
	
		_ccchep := AllTrim(SZX->ZX_I_CCHEP)
		_cchep := "C"
			
	Else
	
		_ccchep := Space(10)
		_cchep := "P"
	
	EndIf
		aAdd(_aVetor,{ "A1_FILIAL"	, xFilial("SA1")								,Nil})
		aAdd(_aVetor,{ "A1_NOME"	, LEFT(_cNome,Len(SA1->A1_NOME))				,Nil})
		aAdd(_aVetor,{ "A1_PESSOA"	, SZX->ZX_PESSOA								,Nil})
		aAdd(_aVetor,{ "A1_CGC"		, SZX->ZX_CGC									,Nil})
		aAdd(_aVetor,{ "A1_NREDUZ"	, LEFT(_cNReduz,Len(SA1->A1_NREDUZ))			,Nil})
		aAdd(_aVetor,{ "A1_TIPO"	, SZX->ZX_TIPO									,Nil})
		aAdd(_aVetor,{ "A1_EST"		, _cEst											,Nil})
		aAdd(_aVetor,{ "A1_COD_MUN"	, CC2->CC2_CODMUN								,Nil})
		aAdd(_aVetor,{ "A1_CEP"		, SZX->ZX_CEP									,Nil})
		aAdd(_aVetor,{ "A1_DDD"		, SZX->ZX_DDD									,Nil})
		aAdd(_aVetor,{ "A1_TEL"		, SZX->ZX_TEL									,Nil})
		aAdd(_aVetor,{ "A1_END"		, _cEnd											,Nil}) 
		aAdd(_aVetor,{ "A1_BAIRRO"	, _cBairro										,Nil}) 
		aAdd(_aVetor,{ "A1_TELEX"	, SZX->ZX_TELEX									,Nil})	
		aAdd(_aVetor,{ "A1_FAX"		, SZX->ZX_FAX									,Nil})	
		aAdd(_aVetor,{ "A1_PAIS"	, SZX->ZX_PAIS									,Nil})	
		aAdd(_aVetor,{ "A1_CONTATO"	, _cContato										,Nil})		
		aAdd(_aVetor,{ "A1_INSCR"	, _cInscr										,Nil})	
		aAdd(_aVetor,{ "A1_PFISICA"	, SZX->ZX_PFISICA								,Nil})	
		aAdd(_aVetor,{ "A1_DTNASC"	, SZX->ZX_DTNASC								,Nil})	
		aAdd(_aVetor,{ "A1_EMAIL"	, SZX->ZX_EMAIL									,Nil})	
		aAdd(_aVetor,{ "A1_HPAGE"	, SZX->ZX_HPAGE									,Nil})	
		aAdd(_aVetor,{ "A1_INSCRM"	, SZX->ZX_INSCRM								,Nil})	
		aAdd(_aVetor,{ "A1_INSCRUR"	, SZX->ZX_INSCRUR								,Nil})	
		aAdd(_aVetor,{ "A1_COMPLEM"	, _cComplem										,Nil})	
		aAdd(_aVetor,{ "A1_MSBLQL"	, "2"											,Nil})	
		aAdd(_aVetor,{ "A1_ESTC"	, _cEst											,Nil})	
		aAdd(_aVetor,{ "A1_CEPC"	, SZX->ZX_CEP									,Nil})	
		aAdd(_aVetor,{ "A1_ENDCOB"	, _cEnd											,Nil})	
		aAdd(_aVetor,{ "A1_BAIRROC"	, _cBairro										,Nil})
		aAdd(_aVetor,{ "A1_VEND"	, SZX->ZX_VEND									,Nil})	
		aAdd(_aVetor,{ "A1_GRPVEN"	, SZX->ZX_I_GRPVE								,Nil})

		If _cEst $ _cUfMVA .And. SZX->ZX_SIMPNAC == "1" // Cliente do Parana e Optante do /simples nacional.
		   aAdd(_aVetor,{ "A1_GRPTRIB"	, _cTRIBMVA     							,Nil}) // "023" / Solicitação chamado 44096.
		EndIf 

        SA3->(DBSetOrder(1)) 
		If SA3->(MsSeek(xFilial("SA3")+SZX->ZX_VEND))
           If SA3->A3_I_VBROK == 'B' .And. _lConsdBrk // Quando True considera os valores de limite de crédito do Broker. Quando False considera o limite de crédito do cadastro de clientes.
			  aAdd(_aVetor,{ "A1_LC"		, SA3->A3_I_LC     ,Nil})
			  aAdd(_aVetor,{ "A1_RISCO"	, SA3->A3_I_RISCO  ,Nil}) 
			  aAdd(_aVetor,{ "A1_TABELA"  , SA3->A3_I_TABPR  ,Nil}) 
			  //			EndIf
			  //			_cBoleto := "S"
           Else 
			   aAdd(_aVetor,{ "A1_LC"		, SZX->ZX_I_LC	    ,Nil})			
			   aAdd(_aVetor,{ "A1_RISCO"	, SZX->ZX_I_RISCO   ,Nil})			
               If SZX->ZX_SIMPNAC == "1"
		          aAdd(_aVetor,{ "A1_TABELA"  , SA3->A3_I_TABSN ,Nil}) 
			   EndIf 
		    EndIf       
		 EndIf
		aAdd(_aVetor,{ "A1_I_DTCAD"	, dDatabase										,Nil})
		aAdd(_aVetor,{ "A1_COND"	, SZX->ZX_CONDPAG								,Nil})
		aAdd(_aVetor,{ "A1_I_CHEP"	, _cchep										,Nil})
		aAdd(_aVetor,{ "A1_I_CCHEP"	, _ccchep										,Nil})
		aAdd(_aVetor,{ "A1_I_CARGC"	, _cCarGc										,Nil})
		aAdd(_aVetor,{ "A1_I_GRCLI"	, SZX->ZX_GRCLI					 				,Nil})
		aAdd(_aVetor,{ "A1_I_CMUNC"	, CC2->CC2_CODMUN								,Nil})
		aAdd(_aVetor,{ "A1_I_EMAIL"	, SZX->ZX_EMAILC				 				,Nil})
		aAdd(_aVetor,{ "A1_NATUREZ"  , "111001"  									,Nil})  
		aAdd(_aVetor,{ "A1_VENCLC"	, SZX->ZX_I_VENCL 								,Nil})
		aAdd(_aVetor,{ "A1_CODPAIS"	, "01058"				  						,Nil})
		aAdd(_aVetor,{ "A1_I_ACRED" , SZX->ZX_I_ACRED								,Nil})
		aAdd(_aVetor,{ "A1_CONTRIB"	, SZX->ZX_CONTRIB								,Nil})
		aAdd(_aVetor,{ "A1_CNAE"    , LEFT(SZX->ZX_I_END,Len(SA1->A1_CNAE))         ,Nil})
		aAdd(_aVetor,{ "A1_SIMPNAC"	, SZX->ZX_SIMPNAC								,Nil})
		aAdd(_aVetor,{ "A1_I_IBOLE"	, _cBoleto										,Nil}) 
	    aAdd(_aVetor,{ "A1_I_SUBCO"	, SZX->ZX_SUB_COD								,Nil}) 

	If _nCodAux > 1
		aAdd( _aVetor , { "A1_COD" , _cCodAux , Nil } )
	EndIf

    If SA1->(FieldPos("A1_I_ORIGD")) > 0
       aAdd(_aVetor,{"A1_I_ORIGD", SZX->ZX_I_ORIGD		  ,Nil})
    EndIf    
    
    If SA1->(FieldPos("A1_I_DW")) > 0         
       aAdd(_aVetor,{"A1_I_SLC"	, SZX->ZX_I_SLC		,Nil})  
	   aAdd(_aVetor,{"A1_I_DW" 	, SZX->ZX_I_DW		,Nil})  
    EndIf 

	nNRelmp		:= 2
	lMsErroAuto	:= .F.
	_aVetor:=U_AcertaDados("SA1",_aVetor)//por causado MVC 
	//===========================================================================
	//| Chama ExecAuto do Cadastro de Clientes                                  |
	//===========================================================================

    If _lMVCSA1  
        MSExecAuto( {|x,y,z| CRMA980(x,y,z) } , _aVetor , 3 ,{} ) // SIGA AUTO PARA A INCLUSAO DO CLIENTE
    Else 
		MSExecAuto( {|x,y| Mata030(x,y)} , _aVetor , 3 ) 
    EndIf 
	
	//===========================================================================
	//| Verifica o status do processamento                                      |
	//===========================================================================
	If lMsErroAuto
	
	   Mostraerro()
	   nNRelmp := 1
		
	Else
	
		//===========================================================================
		//| Verifica o cadastro após a conclusão                                    |
		//===========================================================================
		DBSelectArea("SA1")
		SA1->( DBSetOrder(3) )
		SA1->( DBGoTop() )
		If !SA1->( DBSeek( xFilial("SA1") + _aVetor[04][02] ) )
		
			nNRelmp := 1
		
		EndIf
	
	EndIf

EndIf

//===========================================================================
//| Tratativa para os casos que falham na inclusão                          |
//===========================================================================
If nNRelmp == 1

	//===============================================================================================
	// DESFAZ O PROCESSO PELO CONTROLE DE TRANSACAO
	//===============================================================================================
	DisarmTransaction()
	
	If lMsErroAuto
	
		cNomArqErro	:= NomeAutoLog()
		cNomNovArq	:= __RELDIR + "SA1MIME.##R"
		MostraErro()
		
		If MsErase( cNomNovArq )
		   If ! Empty(cNomArqErro) .And. File(cNomArqErro)
			  __CopyFile( cNomArqErro , cNomNovArq )
		   EndIf 
		EndIf
		
		If ValType(cNomArqErro) == "C"
		   U_ItConout(cNomArqErro)
	    EndIf 
	EndIf
	
//===========================================================================
//| Tratativa para os casos que foram incluídos com sucesso                 |
//===========================================================================
ElseIf nNRelmp == 2
	
	//===========================================================================
	//| Registra o Status de "Importado" para o Prospect                        |
	//===========================================================================
	SZX->( RecLock( "SZX" , .F. ) )
		SZX->ZX_STATUS	:= "I"
		SZX->ZX_CLIENTE	:= SA1->A1_COD
		SZX->ZX_LOJA	:= SA1->A1_LOJA
	SZX->(MSUnLock())
	
	//===========================================================================
	//| Gravação das Referências e Dados Bancários                              |
	//===========================================================================
	If !Empty(AllTrim(SZX->ZX_RC1CONT)) .Or.!Empty(AllTrim(SZX->ZX_RC1EMP))
		
		DBSelectArea("SAO")
		SAO->( RecLock( "SAO" , .T. ) )
		
			SAO->AO_FILIAL	:= xFilial("SAO")
			SAO->AO_CLIENTE	:= SA1->A1_COD
			SAO->AO_LOJA	:= SA1->A1_LOJA
			SAO->AO_TIPO	:= "2"
			SAO->AO_NOMINS	:= SZX->ZX_RC1EMP
			SAO->AO_DATA	:= dDataBase
			SAO->AO_TELEFON	:= SZX->ZX_RC1TEL
			SAO->AO_CONTATO	:= SZX->ZX_RC1CONT
			
		SAO->( MSUnLock() )
		
	EndIf
	
	If !Empty(AllTrim(SZX->ZX_RC2CONT)) .Or.!Empty(AllTrim(SZX->ZX_RC2EMP))
		
		DBSelectArea("SAO")
		SAO->( RecLock("SAO",.T.) )
		
			SAO->AO_FILIAL	:= xFilial("SAO")
			SAO->AO_CLIENTE	:= SA1->A1_COD
			SAO->AO_LOJA	:= SA1->A1_LOJA
			SAO->AO_TIPO	:= "2"
			SAO->AO_NOMINS	:= SZX->ZX_RC2EMP
			SAO->AO_DATA	:= dDataBase
			SAO->AO_TELEFON	:= SZX->ZX_RC2TEL
			SAO->AO_CONTATO	:= SZX->ZX_RC2CONT
			
		SAO->( MSUnLock() )
		
	EndIf
	
EndIf

End Sequence 

//===============================================================================================
// FECHA CONTROLE DE TRANSACAO
//===============================================================================================
EndTran()
MSUnLockAll()

//===============================================================================================
// Mensagem de conclusão do Processamento
//===============================================================================================
If nNRelmp == 1
	U_ITMsg( "Não foi possível efetivar o cadastro, verifique os dados do Prospect e tente novamente."	,,,1 )
ElseIf nNRelmp == 2
	U_ITMsg( "Cadastro efetivado com sucesso!"															,,,2 )
EndIf

Return( .T. )

/*
===============================================================================================================================
Programa----------: AOMS014T
Autor-------------: Erich Buttner
Data da Criacao---: 16/04/2013
Descrição---------: Efetivação do cadastro de prospect (novo cliente)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS014T()

Local nOpca	:= 0
Local aButtons := {}

//Valida se cadastro não está na base de dados
If AOMS014V(SZX->ZX_CGC)
	Return
EndIf

// Valida a parte de limite de crédito.
If ! U_AOMS014W("CREDITO")
   Return 
EndIf 

//Atualiza via Cisp na hora de efetivar
regtomemory("SZX")
FWMsgRun(,{|oproc| U_AOMS014B(2,oproc)},"Aguarde...","Aguarde")
		
//Grava alteração
u_itmemtor("SZX")

//adiciona botoes na Enchoice                       
aAdd( aButtons, { "CISP", {|| FWMsgRun(,{|oproc| U_AOMS014B(2,oproc)},"Aguarde...","Aguarde")}, "At. Cisp", "At. Cisp" } ) 
aAdd( aButtons, { "CRED", {|| FWMsgRun(,{|oproc| U_TelCred(1)},"Aguarde...","Aguarde")}, "An. Cred", "An. Cred" } ) 



nOpca := AxVisual(	"SZX"	,;	//<cAlias>
					9999	,;	//<nReg>
					2		,;	//<nOpc>
							,;	//<aAcho>
							,;	//<nColMens>
							,;	//<cMensagem>
							,;	//<cFunc>
				aButtons	,;	//<aButtons>
					.F.		 )	//<lMaximized>

If nOpca == 1

	U_AOMS014E()
			
EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS014Y
Autor-------------: Josué Danich
Data da Criacao---: 16/04/2013
Descrição---------: Alteração do cadastro de prospect (novo cliente)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS014Y()

Local nOpca	:= 0

Private  aButtons := {}
Private cCadastro := "Alteração de Prospect" // título da tela                                                                     

//Valida se cadastro não está na base de dados
AOMS014V(SZX->ZX_CGC)

//Tenta atualização Cisp primeiro
If Empty(AllTrim(SZX->ZX_SITST))

   regtomemory("SZX")
   FWMsgRun(,{|oproc| U_AOMS014B(2,oproc)},"Aguarde...","Aguarde")
		
   //Grava alteração
   u_itmemtor("SZX")
   
EndIf

//adiciona botoes na Enchoice                       
aAdd( aButtons, { "CISP", {|| FWMsgRun(,{|oproc| U_AOMS014B(2,oproc)},"Aguarde...","Aguarde")}, "At. Cisp", "At. Cisp" } ) 
aAdd( aButtons, { "CRED", {|| FWMsgRun(,{|oproc| U_TelCred(1)},"Aguarde...","Aguarde")}, "An. Cred", "An. Cred" } ) 


nOpca := AxAltera("SZX",SZX->(Recno()),4,,,,,,,, aButtons,,,,.T.,,,,,)

Return


/*
===============================================================================================================================
Programa--------: AOMS014R
Autor-----------: Talita
Data da Criacao-: 27/10/2014
Descrição-------: Incluido na rotina a opção de exclusão do prospect, onde quando o credito excluir será aberta uma tela para
----------------: preenchimento do motivo da recusa e após a confirmação será encaminhado um e-mail com a ficha do prospect e
----------------: motivo da exclusão. Chamado: 7858
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

User Function AOMS014R() 
  
Local _nOpc := AxVisual(	"SZX"	,;	//<cAlias>
							9999	,;	//<nReg>
							4		,;	//<nOpc>
									,;	//<aAcho>
									,;	//<nColMens>
									,;	//<cMensagem>
									,;	//<cFunc>
									,;	//<aButtons>
							.T.		 )	//<lMaximized>

If _nOpc == 1

    SA3->( DBSetOrder (1) )
    If SA3->( DBSeek( xFilial("SA3") + SZX->ZX_VEND ) )
    	cEmail := AllTrim( SA3->A3_EMAIL )
	Else
	    cEmail := "Vendendor não encontrado: "+xFilial("SA3") +" "+ SZX->ZX_VEND
    EndIf
	cMens1 := ""
	cGetCc := SuperGetMV("IT_EMCCEP",.F.,"sistema@italac.com.br")+Space(200)//EMail Com Copia Exclusão Prospect
	_nTam:=205
	_nCol:=009 
	_nLin:=005 
	
	DEFINE FONT oFont NAME "Tahoma" BOLD
	
	DEFINE MSDIALOG oDlg TITLE "Exclusão de Prospect" From 0,0 to 350,500 Of oMainWnd PIXEL
	
		oTPanel1:= TPanel():New(0,0,"",oDlg,NIL,.T.,.F.,NIL,NIL,450,200,.T.,.F.)
		
		@ _nLin,_nCol Say "Informe o Motivo da Exclusão do Prospect"				Of oTPanel1 Pixel FONT oFont
		_nLin+=11
	  	@ _nLin,_nCol Say "Nome.........: "+	Upper( AllTrim( SZX->ZX_NOME ) )	Of oTPanel1 Pixel
		_nLin+=10
		@ _nLin,_nCol Say "CGC...........: "+	SZX->ZX_CGC							Of oTPanel1 Pixel
		_nLin+=10
		@ _nLin,_nCol Say "Email para..: "+cEmail 									Of oTPanel1 Pixel
		_nLin+=11
		@ _nLin,_nCol Say "Com Copia.: "        									Of oTPanel1 Pixel
		_nCol+=31
		_nLin-=02
		@ _nLin,_nCol Get cGetCc  Size _nTam,10        								Of oTPanel1 Pixel
		_nLin+=11
		
		oTFolder1 := TFolder():New( _nLin,005,{"Motivo"},,oTPanel1,,,,.T.,,245,090 )
	
		@ 005,005 Get oMemo01 var cMens1 MEMO Size 230,60 when .T.					of oTFolder1:aDialogs[1] Pixel
		_nLin+=95		
		TButton():New(_nLin,010, ' Confirma ', oTPanel1,{|| AOMS014R(AllTrim(cGetCc)) },70,15,,,,.T.)
		TButton():New(_nLin,090, ' Cancela ' , oTPanel1,{|| oDlg:END()                },70,15,,,,.T.)
		
	ACTIVATE MSDIALOG oDlg Centered

EndIf

Return

/*
===============================================================================================================================
Programa--------: AOMS014R
Autor-----------: Talita
Data da Criacao-: 27/10/2014
Descrição-------: Incluido na rotina a opção de exclusão do prospect, onde quando o credito excluir será aberta uma tela para
----------------: preenchimento do motivo da recusa e após a confirmação será encaminhado um e-mail com a ficha do prospect e
----------------: motivo da exclusão. Chamado: 7858
Parametros------: cGetCc
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function AOMS014R(cGetCc)

Local EnvEmail := .F.
Local _aConfig := U_ITCFGEML('')
Local _cEmlLog := ""
Private cEmail := SuperGetMV("IT_EMCCEP",.F.,"sistema@italac.com.br")
DEFAULT cGetCc := SuperGetMV("IT_EMCCEP",.F.,"sistema@italac.com.br")

DBSelectArea("SA3")
SA3->( DBSetOrder (1) )
If SA3->( DBSeek( xFilial("SA3") + SZX->ZX_VEND ) )
	cEmail := AllTrim( SA3->A3_EMAIL )
EndIf

If cEmail <> ""
		
	cMsg := '<table width="75%" border="1">' 
	cMsg += '<tr>'  
	cMsg += '<td bordercolor="#000000" bgcolor="#778899"><div align="center"><font color="#FFFFFF">AVISO DE EXCLUSÃO DE PROSPECT</font></div></td>'
	cMsg += '</tr>'
	cMsg += '</table>'
	cMsg += '<BR>'
	cMsg += '<table width="75%" border="1">'
	cMsg += '<tr>'
	cMsg += '<td bordercolor="#000000" bgcolor="#778899"><div align="center"><font color="#FFFFFF">DADOS GERAIS</font></div></td>'
	cMsg += '</tr>'
	cMsg += '</table>'
	cMsg += '<tr>'
	cMsg += '<table width="75%" border="1"> '
	cMsg += '<tr>'
	cMsg += '<td><strong>Tipo: </strong>'+"Revendedor"+'</td>' 
	
	If SZX->ZX_PESSOA == 'J'
		cMsg += '<td><strong>Pessoa: </strong>'+"Juridica"+'</td>'
	Else 
		cMsg += '<td><strong>Pessoa: </strong>'+"Fisica"+'</td>'
	EndIf
	
	cMsg += '</table>'
	cMsg += '<BR>'
	cMsg += '<table width="75%" border="1">'
	cMsg += '<td><strong>CGC: </strong>'+Transform(SZX->ZX_CGC,"@R! NN.NNN.NNN/NNNN-99")+'</td>'
	cMsg += '<td><strong>Inscrição Estadual: </strong>'+SZX->ZX_INSCR+'</td>'
	cMsg += '</table>'
	cMsg += '<table width="75%" border="1">'
	cMsg += '<td><strong>Nome: </strong>'+SZX->ZX_NOME+' </td>'
	cMsg += '</table>'
	cMsg += '<table width="75%" border="1">'
	cMsg += '<td><strong>Nome Fantasia: </strong>'+SZX->ZX_NREDUZ+' </td>'
	cMsg += '</table>'
	cMsg += '<table width="75%" border="1">'
	cMsg += '<td><strong>Data de Emissão: </strong>'+DToC(SZX->ZX_EMISSAO)+' </td>'
	cMsg += '<td><strong>Data de Fundação: </strong>'+DToC(SZX->ZX_DTNASC)+' </td>'
	cMsg += '</table>'
	cMsg += '<table width="75%" border="1">'
	cMsg += '<td><strong>E-mail: </strong>'+SZX->ZX_EMAIL+' </td>'
	cMsg += '<td><strong>Home Page: </strong>'+SZX->ZX_HPAGE+' </td>'
	cMsg += '</table>'
	cMsg += '<table width="75%" border="1">'
	cMsg += '<td><strong>Condição de Pagamento: </strong>'+SZX->ZX_CONDPAG+ " - "+AllTrim(Posicione("SE4",1,xFilial("SE4")+SZX->ZX_CONDPAG,"SE4->E4_DESCRI"))+' </td>'
	
	If SZX->ZX_CHEP = 'S'
	cMsg += '<td><strong>Cadastro na Chep: </strong>'+"Sim"+' </td>'
	Else  
	cMsg += '<td><strong>Cadastro na Chep: </strong>'+"Não"+' </td>'
	EndIf
	
	cMsg += '<td><strong>Cod. Chep: </strong>'+SZX->ZX_I_CCHEP+' </td>'
	cMsg += '</table>'
	cMsg += '<table width="75%" border="1">'
	cMsg += '<td><strong>Segmento: </strong>'+SZX->ZX_GRCLI+ " - " + AllTrim(Posicione("ZZ6",1,xFilial("ZZ6")+SZX->ZX_GRCLI,"ZZ6->ZZ6_DESCRO"))+' </td>'
	cMsg += '</table>'
	cMsg += '<br>'
	cMsg += '<table width="75%" border="1">'
	cMsg += '<tr>'
	cMsg += '<td bordercolor="#000000" bgcolor="#778899"><div align="center"><font color="#FFFFFF">ENDEREÇO</font></div></td>'
	cMsg += '</tr>'
	cMsg += '</table>'
	cMsg += '<table width="75%" border="1">'
	cMsg += '<td><strong>Estado: </strong>'+SZX->ZX_EST+' </td>'
	cMsg += '<td><strong>Código de Municipio: </strong>'+SZX->ZX_CODMUN+' </td>'
	cMsg += '</table>'
	cMsg += '<table width="75%" border="1">'
	cMsg += '<td><strong>Municipio: </strong>'+AllTrim(Posicione("CC2",1,xFilial("CC2")+SZX->ZX_EST+SZX->ZX_CODMUN,"CC2->CC2_MUN"))+' </td>'
	cMsg += '</table>'
	cMsg += '<table width="75%" border="1">'
	cMsg += '<td><strong>CEP: </strong>'+SZX->ZX_CEP+' </td>'
	cMsg += '</table>'
	cMsg += '<table width="75%" border="1">'
	cMsg += '<td><strong>Endereço: </strong>'+SZX->ZX_END+' </td>'
	cMsg += '</table>'
	cMsg += '<table width="75%" border="1">'
	cMsg += '<td><strong>Complemento: </strong>'+SZX->ZX_COMPLEM+' </td>'
	cMsg += '</table>'
	cMsg += '<table width="75%" border="1">'
	cMsg += '<td><strong>Bairro: </strong>'+SZX->ZX_BAIRRO+' </td>'
	cMsg += '</table>'
	cMsg += '<table width="75%" border="1">'
	cMsg += '<td><strong>DDD: </strong>'+SZX->ZX_DDD+' </td>'
	cMsg += '<td><strong>Telefone: </strong>'+SZX->ZX_TEL+' </td>'
	cMsg += '<td><strong>Fax: </strong>'+SZX->ZX_FAX+' </td>'
	cMsg += '</table>'
	cMsg += '<BR>'
	cMsg += '<table width="75%" border="1">'
	cMsg += '<tr>'
	cMsg += '<td bordercolor="#000000" bgcolor="#778899"><div align="center"><font color="#FFFFFF">OBSERVAÇÕES</font></div></td>'
	cMsg += '</tr>'
	cMsg += '</table>'
	cMsg += '<table width="75%" border="1">'
	cMsg += '<td><strong>Obs.: </strong>'+SZX->ZX_OBS+' </td>'
	cMsg += '</table>'
	cMsg += '<br>'
	cMsg += '<table width="75%" border="1">'
	cMsg += '<tr>'
	cMsg += '<td bordercolor="#000000" bgcolor="#778899"><div align="center"><font color="#FFFFFF">CONTATO</font></div></td>'
	cMsg += '</tr>'
	cMsg += '</table>'
	cMsg += '<table width="75%" border="1"> '
	cMsg += '<td><strong>Nome do Contato: </strong>'+SZX->ZX_CONTATO+' </td>'
	cMsg += '<td><strong>Cargo do Contato: </strong>'+SZX->ZX_CARGC+' </td>'
	cMsg += '<td><strong>E-mail do Contato: </strong>'+SZX->ZX_EMAILC+' </td>'
	cMsg += '</table>'
	cMsg += '<br>' 
	cMsg += '<table width="75%" border="1">'
	cMsg += '<tr>'
	cMsg += '<td bordercolor="#000000" bgcolor="#778899"><div align="center"><font color="#FFFFFF">REFERENCIA COMERCIAL</font></div></td>'
	cMsg += '</tr>'
	cMsg += '</table>'
	cMsg += '<table width="75%" border="1">'
	cMsg += '<td><strong>Empresa: </strong>'+SZX->ZX_RC1EMP+' </td>'
	cMsg += '<td><strong>Telefone: </strong>'+SZX->ZX_RC1TEL+' </td>'
	cMsg += '<td><strong>Nome: </strong>'+SZX->ZX_RC1CONT+' </td>'
	cMsg += '</table>'
	cMsg += '<table width="75%" border="1">'
	cMsg += '<td><strong>Empresa: </strong>'+SZX->ZX_RC2EMP+' </td>'
	cMsg += '<td><strong>Telefone: </strong>'+SZX->ZX_RC2TEL+' </td>'
	cMsg += '<td><strong>Nome: </strong>'+SZX->ZX_RC2CONT+' </td>'
	cMsg += '</table>'
	cMsg += '<BR>'
	cMsg += '<table width="75%" border="1">'
	cMsg += '<tr>'
	cMsg += '<td bordercolor="#000000" bgcolor="#778899"><div align="center"><font color="#FFFFFF">OBSERVAÇÕES ANALISE DE CRÉDITO</font></div></td>'
	cMsg += '</tr>'
	cMsg += '</table>'
	cMsg += '<table width="75%" border="1"> '
	cMsg += '<td><strong>Obs. Crédito: </strong>'+SZX->ZX_I_ACRED+' </td>'
	cMsg += '</table>'
	cMsg += '<table width="75%" border="1"> '
	cMsg += '<td><strong>Motivo da Recusa: </strong>'+cMens1+' </td>'
	cMsg += '</table>'
	cMsg += '</tr>'
	

//    ITEnvMail(cFrom         ,cEmailTo,cEmailCo,cEmailBcc,cAssunto                  ,cMensagem,cAttach,cAccount    ,cPassword   ,cServer      ,cPortCon    ,lRelauth     ,cUserAut     ,cPassAut     ,cLogErro)
	U_ITENVMAIL( _aConfig[01] , cEmail ,cGetCc  ,         ,"Prospect: "+ SZX->ZX_NOME, cMsg ,         ,_aConfig[01],_aConfig[02], _aConfig[03],_aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )

	If _cEmlLog == "Sucesso: e-mail enviado corretamente!"
		EnvEmail := .T.
		U_ITMsg("Enviado email de aviso ao representante: " + cEmail+ " / Com copia:  "+cGetCc,,,3)
	Else
		U_ITMsg("Falha no envio do email de aviso ao representante: " + _cEmlLog,,,1)
	EndIf

Else
	
	U_ITMsg(  "E-mail não encontrado!" ,"Erro de email", "Favor verificar o código do vendedor e se o e-mail do vendedor está preenchido!",1)

EndIf

If EnvEmail

	RecLock( "SZX" , .F. )
 	SZX->ZX_MOTREC := cMens1
	SZX->( DbDelete() )
	SZX->( MSUnLock() )
	
EndIf

oDlg:END()

Return( .T. )

/*
===============================================================================================================================
Programa--------: AOMS014S
Autor-----------: Darcio Ribeiro Spörl
Data da Criacao-: 19/12/2016
Descrição-------: Função criada para tirar todos os caracteres especiais de uma variável texto
Parametros------: _cTexto	- Texto a serem retirados os caracteres especiais
Retorno---------: _cRet		- Retorna o texto limpo sem os caracteres especiais
===============================================================================================================================
*/
User Function AOMS014S(_cTexto)
Local _aCarc_Esp	:= {}
Local _nI			:= 0
Local _cRet			:= _cTexto

aAdd(_aCarc_Esp,{"!", ""})
aAdd(_aCarc_Esp,{"#", ""})
aAdd(_aCarc_Esp,{"$", ""})
//aAdd(_aCarc_Esp,{"&", ""})
aAdd(_aCarc_Esp,{"%", ""})
aAdd(_aCarc_Esp,{"*", ""})
//aAdd(_aCarc_Esp,{"/", ""})
aAdd(_aCarc_Esp,{"(", ""})
aAdd(_aCarc_Esp,{")", ""})
aAdd(_aCarc_Esp,{"+", ""})
aAdd(_aCarc_Esp,{"¨", ""})
aAdd(_aCarc_Esp,{"=", ""})
aAdd(_aCarc_Esp,{"~", ""})
aAdd(_aCarc_Esp,{"^", ""})
aAdd(_aCarc_Esp,{"]", ""})
aAdd(_aCarc_Esp,{"[", ""})
aAdd(_aCarc_Esp,{"{", ""})
aAdd(_aCarc_Esp,{"}", ""})
aAdd(_aCarc_Esp,{";", ""})
aAdd(_aCarc_Esp,{":", ""})
aAdd(_aCarc_Esp,{">", ""})
aAdd(_aCarc_Esp,{"<", ""})
aAdd(_aCarc_Esp,{"?", ""})
aAdd(_aCarc_Esp,{"_", ""})
aAdd(_aCarc_Esp,{",", ""})
aAdd(_aCarc_Esp,{"'", ""})
aAdd(_aCarc_Esp,{"  ", " "})
aAdd(_aCarc_Esp,{"   ", " "})
aAdd(_aCarc_Esp,{"    ", " "})
aAdd(_aCarc_Esp,{"     ", " "})
aAdd(_aCarc_Esp,{"      ", " "})
aAdd(_aCarc_Esp,{"       ", " "})
aAdd(_aCarc_Esp,{"        ", " "})

//Executa o Laco ate o Tamanho Total do Array
For _nI := 1 To Len(_aCarc_Esp)
	//Verifica se Algum dos Caracteres Especiais foi Digitado
	If _aCarc_Esp[_nI][1] $ AllTrim(_cRet)
		_cRet := StrTran(_cRet, _aCarc_Esp[_nI][1], _aCarc_Esp[_nI][2])
	EndIf
Next

_cRet := Upper(FWNOACCENT(AllTrim(_cRet)))

Return(_cRet)


/*
===============================================================================================================================
Programa--------: AOMS014N
Autor-----------: Josué Danich Prestes
Data da Criacao-: 30/10/2017
Descrição-------: Função criada para tirar todos os caracteres não numéricos de uma variável texto
Parametros------: _cTexto	- Texto a serem retirados os caracteres não numéricos
Retorno---------: _cRet		- Retorna o texto limpo sem os caracteres não numéricos
===============================================================================================================================
*/
User Function AOMS014N(_cTexto)
Local _nI			:= 0
Local _cRet			:= _cTexto

For _nI := 1 to Len(_ctexto)

  If SubStr(_ctexto,_nI,1) != '0' .And. SubStr(_ctexto,_nI,1) != '1' .And. SubStr(_ctexto,_nI,1) != '2';
   			.And. SubStr(_ctexto,_nI,1) != '3' .And. SubStr(_ctexto,_nI,1) != '4' .And. SubStr(_ctexto,_nI,1) != '5' .and.;
   			 SubStr(_ctexto,_nI,1) != '6' .And. SubStr(_ctexto,_nI,1) != '7' .And. SubStr(_ctexto,_nI,1) != '8' .And. SubStr(_ctexto,_nI,1) != '9' 

   	  _cRet := StrTran(_cRet, SubStr(_ctexto,_nI,1) , "")

  EndIf
  
Next

Return(_cRet)

/*
===============================================================================================================================
Programa----------: AOMS014A
Autor-------------: Josué Danich Prestes
Data da Criacao---: 04/03/2013
Descrição---------: Alteração de Cadastro de Prospect (Novo Cliente)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS014A()

Local _aCodAux		:= {}
Local _cCodAux		:= ""
Local _nCodAux		:= 0
Local nNRelmp		:= 0
Local _cQuery		:= ""
Local _cAlias		:= ""
Local _cInscr		:= ""

Private lMsErroAuto	:= .F.

If Empty(M->ZX_SIMPNAC)

	U_ITMsg("É obrigatorio selecionar se o cliente é Simples Nacional","Atenção","Selecione se o cliente é Simples Nacional",1)
	Return
	
EndIf

If Empty(M->ZX_CONTRIB)

	U_ITMsg("É obrigatorio selecionar se o cliente é Contribuinte ICMS","Atenção","Selecione se o cliente é Contribuinte ICMS",1)
	Return
	
EndIf


DBSelectArea('SA3')
SA3->( DBSetOrder(1) )
If SA3->( DBSeek( xFilial('SA3') + M->ZX_VEND ) )
	
	If SA3->A3_I_TIPV <> 'V'
	
	
		U_ITMsg('O cadastro atual não pode ser efetivado pois o vendedor amarrado ao Cliente não está classificado como Vendedor!',"Validação  de vendedor",;
				'Verifique os dados informados e/ou o cadastro do Vendedor no Sistema antes de solicitar a efetivação.',1)
			
		Return

	EndIf
	
	If SA3->A3_MSBLQL == '1'
	
		U_ITMsg('O cadastro atual não pode ser efetivado pois o vendedor amarrado ao Cliente está bloqueado no sistema!',"Validação  de vendedor",;
				'Verifique os dados informados e/ou o cadastro do Vendedor no Sistema antes de solicitar a efetivação.',1)
				
		Return

	EndIf
	
Else

	U_ITMsg('O cadastro atual não pode ser efetivado pois o vendedor amarrado ao Cliente não é válido no cadastro do Sistema!',"Validação  de vendedor",;
				'Verifique os dados informados e/ou o cadastro do Vendedor no Sistema antes de solicitar a efetivação.',1)

	
	Return
	
EndIf

//Validação da inscrição estadual
If AllTrim(M->ZX_INSCR) != "ISENTO"

	_cInscr		:= U_AOMS014N(M->ZX_INSCR)

Else

	_cInscr     := "ISENTO"

EndIf

M->A1_INSCR := _cInscr
M->A1_EST   := U_AOMS014S(SZX->ZX_EST)

If !(IE(M->A1_INSCR,M->A1_EST) .And. A030VldUCod()) .Or. Empty(_cInscr)

  U_ITMsg("Falha na validação da inscrição estadual!","Validação de inscrição estadual","Verifique a inscrição estadual no sintegra e digite somente os números ou ISENTO",1)
  
  Return
  
EndIf                                                                                  

//===============================================================================================
// ABRE CONTROLE DE TRANSACAO
//===============================================================================================
BeginTran()

Begin Sequence

DBSelectArea("CC2")
CC2->( DBSetOrder(1) )
CC2->( DBSeek( xFilial("CC2") + M->ZX_EST + M->ZX_CODMUN ) )

DBSelectArea("SA1")
SA1->( DBSetOrder(3) )
If SA1->( DBSeek( xFilial("SA1") + M->ZX_CGC ) )

	U_ITMsg(	"O CPF/CNPJ informado já existe no cadastro de clientes com o Código/Loja: ["+ SA1->A1_COD +"/"+ SA1->A1_LOJA +"]", "Validação de CNPJ"	,;
					"Não é permitido cadastrar dois Clientes com o mesmo CPF/CNPJ, verifique os cadastros antes de efetivar o Prospect.",1	 )
	
	nNRelmp := 0

Else
	
	_cQuery := " SELECT DISTINCT "
	_cQuery += "     A1_COD     ,"
	_cQuery += "     A1_MSBLQL   "
	_cQuery += " FROM  "+ RETSQLNAME('SA1') +" SA1 "
	_cQuery += " WHERE "+ RETSQLCOND('SA1')
	_cQuery += " AND A1_CGC     LIKE '"+ SubStr( M->ZX_CGC , 1 , 8 ) +"%' "
	_cQuery += " ORDER BY A1_COD "
	
	_cAlias := GetNextAlias()
	
	If Select(_cAlias) > 0
		(_cAlias)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , 'TopConn' , TcGenQry(,,_cQuery) , _cAlias , .F. , .T. )
	
	_cCodAux := ""
	_nCodAux := 0
	
	DBSelectArea(_cAlias)
	(_cAlias)->( DBGoTop() )
	While (_cAlias)->( !Eof() )
	
		aAdd( _aCodAux , { (_cAlias)->A1_COD , IIf( (_cAlias)->A1_MSBLQL == '1' , 'Bloqueado' , 'Ativo' ) } )
		
		If _cCodAux <> (_cAlias)->A1_COD
			_cCodAux := (_cAlias)->A1_COD
			_nCodAux++
		EndIf
		
	(_cAlias)->( DBSkip() )
	EndDo
	
	(_cAlias)->( DBCloseArea() )
	
	If _nCodAux > 1
		
		U_ITMsg( 'Existe mais um código de cliente cadastrado para esse CNPJ no sistema. Verifique o código correto e selecione para continuar com a efetivação!' , 'Atenção!' ,,1)
		_cCodAux := U_ITListBox( 'Códigos de cliente encontrados para o CNPJ' , {'Código','Status'} , _aCodAux , .F. , 3 , 'Selecione o código a ser utilizado na efetivação:' ,,{100,100}, 1 )
		
		If Empty( _cCodAux )
		
			U_ITMsg(  'Operação cancelada pelo usuário!' ,,,1 )
			DisarmTransaction()
			Break // Return
			
		EndIf
		
	EndIf
	
	//Grava alteração
	u_itmemtor("SZX")	
   
   nNRelmp := 2 //Registra gravação bem sucedida
	
EndIf

End Sequence
//===============================================================================================
// FECHA CONTROLE DE TRANSACAO
//===============================================================================================
EndTran()
MSUnLockAll()

//===============================================================================================
// Mensagem de conclusão do Processamento
//===============================================================================================
If nNRelmp == 1
	U_ITMsg( "Não foi possível efetivar o cadastro, verifique os dados do Prospect e tente novamente."	,,,1 )
ElseIf nNRelmp == 2
	U_ITMsg( "Cadastro efetivado com sucesso!"															,,,2 )
EndIf

Return( .T. )

/*
===============================================================================================================================
Programa----------: AOMS014B
Autor-------------: Josué Danich
Data da Criacao---: 16/04/2013
Descrição---------: Consulta Cisp
Parametros--------: _natua - tipo de consulta, 1 em segundo plano, 2 em tela
					oproc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS014B(_natua,oproc)

Local cUrlsintegra   // := "https://servicos.cisp.com.br/v1/sintegra/" + AllTrim(M->ZX_CGC)
Local cUrlreceita    // := "https://servicos.cisp.com.br/v1/receita-federal/" + AllTrim(M->ZX_CGC)
Local cUrlsimples    // := "https://servicos.cisp.com.br/v1/simples-nacional/" + AllTrim(M->ZX_CGC)
Local aHeadOut        := {}
Local cHdSintegra     := ""
Local cCorSintegra    := ""
Local _osintegra
Local _asintegra      := {}
Local cHdReceita      := ""
Local cCorReceita     := ""
Local _oReceita
Local _aReceita       := {}
Local _lRet           := .T.
Local _lerro          := .F.
Local _cerro          := ""
Local _lisento 		  := .F.
Local _csintegra    := nil
Local _nI 

Local _nnj			:= 0
Local _lLinkPrd     := U_ItGetMv("IT_LKCISPP", .T.)
Local cUrlcisp      := "https://servicos.cisp.com.br/v1/avaliacao-analitica/raiz/" + SubStr(AllTrim(M->ZX_CGC),1,8)
Local _cpasswd      := u_itgetmv("IT_PWCISP","!t@lac95_01#")
Local _cuser	    := u_itgetmv("IT_USCISP","ws09501")
Local _cDecodeTxt   := ""
Local _cNomeSint, _cNomeRSit

Default oproc         := nil
Default _natua := 2

If _lLinkPrd
   //====================================================================
   // Link base produção
   //====================================================================
   cUrlsintegra := "https://api.maxxi.cisp.com.br/public-bases/v1/sintegra/cnpj/"+ AllTrim(M->ZX_CGC)+"/uf/"+AllTrim(M->ZX_EST)+"?key=dwnljGS5DRJ0BkzGGgRsrNZCUxqdqrZw" //"https://servicos.cisp.com.br/v1/sintegra/" + AllTrim(M->ZX_CGC)
   cUrlreceita  := "https://api.maxxi.cisp.com.br/public-bases/v1/receita-federal/cnpj/"+ AllTrim(M->ZX_CGC) + "?key=dwnljGS5DRJ0BkzGGgRsrNZCUxqdqrZw" //"https://servicos.cisp.com.br/v1/receita-federal/" + AllTrim(M->ZX_CGC)
   cUrlsimples  := "https://api.maxxi.cisp.com.br/public-bases/v1/simples-nacional/cnpj/"+ AllTrim(M->ZX_CGC) + "?key=dwnljGS5DRJ0BkzGGgRsrNZCUxqdqrZw" //"https://servicos.cisp.com.br/v1/simples-nacional/" + AllTrim(M->ZX_CGC)
Else 
   //====================================================================
   // Link base homologação
   //====================================================================
   cUrlsintegra := "https://api-homol.maxxi.cisp.com.br/public-bases/v1/sintegra/cnpj/"+ AllTrim(M->ZX_CGC)+"/uf/"+AllTrim(M->ZX_EST)+"?key=43c629ff-e72e-4172-a0fe-ffdef386573a" //"https://servicos.cisp.com.br/v1/sintegra/" + AllTrim(M->ZX_CGC)
   cUrlreceita  := "https://api-homol.maxxi.cisp.com.br/public-bases/v1/receita-federal/cnpj/"+ AllTrim(M->ZX_CGC) + "?key=43c629ff-e72e-4172-a0fe-ffdef386573a" //"https://servicos.cisp.com.br/v1/receita-federal/" + AllTrim(M->ZX_CGC)
   cUrlsimples  := "https://api-homol.maxxi.cisp.com.br/public-bases/v1/simples-nacional/cnpj/"+ AllTrim(M->ZX_CGC) + "?key=43c629ff-e72e-4172-a0fe-ffdef386573a" //"https://servicos.cisp.com.br/v1/simples-nacional/" + AllTrim(M->ZX_CGC)
EndIf 

//Só atualiza pessoas juridicas
If (M->ZX_PESSOA == "F")

    If _natua == 2
    	U_ITMsg("Não atualiza pessoa física via Cisp","Atenção",,1)
    EndIf

    M->ZX_I_SITRF := " "
    M->ZX_I_DTSRF := " "
  
    M->ZX_SITST := " "
    M->ZX_DTST  := " "

    Return
    
EndIf

//========================================
// Consultando CISP
//========================================
aHeadOut := {}
aAdd( aHeadOut , "Authorization: Basic "+Encode64(_cuser + ":" + _cpasswd ) )
_cNome   := ""
_cNReduz := ""

//Faz chamada ao webservice do cisp
CHdcisp  := ""
cCorcisp := HttpGet(cUrlcisp,"",NIL,aHeadOut,@cHdcisp)

//======================================================
// Descriptografia do JSon Recebido
//======================================================
_cDecodeTxt := ""
If ! Empty(cCorcisp)
	_cDecodeTxt := DecodeUTF8(cCorcisp, "cp1252")   
EndIf 

If ! Empty(_cDecodeTxt)
	cCorcisp := _cDecodeTxt
EndIf 

// Remover caracteres especiais do JSON.
cCorcisp := U_ITSUBCHR(cCorcisp, {{"*",""},{"$",""}})

_ocisp   := nil
_acisp := StrTokArr(cHdcisp,chr(10))

//Verifica e formata resposta do cisp
If SubStr(cHdcisp,1,15) == "HTTP/1.1 200 OK" .And. FWJsonDeserialize(cCorcisp,@_ocisp)
   _cNome   := _ocisp:cliente:razaosocial
   _cNReduz := _ocisp:cliente:nomefantasia
EndIf 


//====================================================
// Consultando Sintegra
//====================================================
//Define usuário e password
aAdd( aHeadOut , "accept:application/json")

If ValType(oproc) = "O"

   	oproc:cCaption := ("Consultando Sintegra...")
	ProcessMessages()
 
EndIf

//====================================
// >> Obtem os dados Link Sintegra. <<
//====================================

//Faz chamada ao webservice do Sintegra
cCorSintegra  := HttpGet(cUrlsintegra,"",NIL,aHeadOut,@cHdSintegra)

//======================================================
// Descriptografia do JSon Recebido
//======================================================
_cDecodeTxt := ""
If ! Empty(cCorSintegra)
	_cDecodeTxt := DecodeUTF8(cCorSintegra, "cp1252")   
EndIf 

If ! Empty(_cDecodeTxt)
	cCorSintegra := _cDecodeTxt
EndIf 

// Remover caracteres especiais do JSON.
cCorSintegra := U_ITSUBCHR(cCorSintegra, {{"*",""},{"$",""}})

If Empty(cCorSintegra)
   If _natua == 2
   	  U_ITMsg("[AOMS014] - Falha na consulta do Sintegra.","Atenção",,1)
   Else 
      ConOut("[AOMS014] - Falha na consulta do Sintegra.") 
   EndIf

   M->ZX_I_SITRF := " "
   M->ZX_I_DTSRF := " "
  
   M->ZX_SITST := " "
   M->ZX_DTST  := " "

   Return
EndIf 

If !(SubStr(cHdSintegra,1,12) == "HTTP/1.1 200")
   If _natua == 2
   	  U_ITMsg("[AOMS014] - Falha na consulta do Sintegra: [ " + AllTrim(cCorSintegra) + " ]","Atenção",,1)
   Else 
      ConOut("[AOMS014] - Falha na consulta do Sintegra: [" + AllTrim(cCorSintegra) + " ]") 
   EndIf

   M->ZX_I_SITRF := " "
   M->ZX_I_DTSRF := " "
  
   M->ZX_SITST := " "
   M->ZX_DTST  := " "

   Return

EndIf 

_lisento := .F.

_oJson := JsonObject():new()

_cRet := _oJson:FromJson(cCorSintegra)

//Verifica e formata resposta do Sintegra 

If ! (ValType(_cRet) == "U") //!(SubStr(cHdSintegra,1,12) == "HTTP/1.1 200" .And. (ValType(_cRet) == "U")) //FWJsonDeserialize(cCorSintegra,@_osintegra) .And. !Empty(_osintegra))
    
    If AllTrim(M->ZX_INSCR) == "ISENTO" .Or. AllTrim(M->ZX_INSCR) == "ISENTA"
    	_lisento := .T.
		Return
    Else
       If _natua == 2
       	  U_ITMsg("Falha no webservice do sintegra, consulta não foi completada","Atenção",cHdSintegra,1)
 
    	  M->ZX_I_SITRF := " "
    	  M->ZX_I_DTSRF := " "
  
   	      M->ZX_SITST := " "
   	      M->ZX_DTST  := " "
    	  
    	  Return
       EndIf
    
      _lRet := .F.
      _lerro := .T.
      _cerro := cHdSintegra
    
      Return
    
    EndIf

EndIf

_aNames := _oJson:GetNames()

_cTipoDocs := ""
_cNrDocs := ""
_cNomeSint := ""
_cNomeRSit := ""

_osintegra := _oJson:GetJsonObject("company")
If (ValType(_osintegra) == "A" .Or. ValType(_osintegra) == "J") .And. ! Empty(_osintegra)
   _osintegra := _osintegra[1]

//---------------------------------------------------
   _aCompany := _osintegra:GetNames() 
   _nI := aScan(_aCompany, "registeredName" )
   If _nI > 0
      _cNomeSint := _osintegra[_aCompany[_nI]]
   EndIf 

   _nI := aScan(_aCompany, "name" )
   If _nI > 0
      _cNomeRSit := _osintegra[_aCompany[_nI]]
   EndIf 
//---------------------------------------------------

   _nI := aScan(_aNames, "updateDate" )
   If _nI > 0
      _cDtAlter := _oJson[_aNames[_nI]]
   EndIf 

   _oDoctos := _osintegra:GetJsonObject("documents") 
   _oDoctos := _oDoctos[1]

   _aNameDocs := _oDoctos:GetNames()

   _nI := aScan(_aNameDocs ,"Type" )
   _cTipoDocs := ""

   If _nI > 0
      _cTipoDocs := _oDoctos[_aNameDocs[_nI]]	  
   EndIf 

   _nI := aScan(_aNameDocs ,"value" )
   _cNrDocs := ""

   If _nI > 0
      _cNrDocs := _oDoctos[_aNameDocs[_nI]]	
      _cNrDocs := StrTran(_cNrDocs,".","")  
   EndIf 

   If Empty(_cNrDocs)
      _cNrDocs := "ISENTO"
   EndIf 
EndIf 

If ValType(oproc) = "O"

      	oproc:cCaption := ("Consultando Receita...")
   		ProcessMessages()
 
EndIf

//===========================================
// >> Obtem os dados Link Receita Federal. <<
//===========================================

//Faz chamada ao webservce da Receita
cCorReceita  := HttpGet(cUrlReceita,"",NIL,aHeadOut,@cHdReceita)

//======================================================
// Descriptografia do JSon Recebido
//======================================================
_cDecodeTxt := ""
If ! Empty(cCorReceita)
	_cDecodeTxt := DecodeUTF8(cCorReceita, "cp1252")   
EndIf 

If ! Empty(_cDecodeTxt)
	cCorReceita := _cDecodeTxt
EndIf 

// Remover caracteres especiais do JSON.
cCorReceita := U_ITSUBCHR(cCorReceita, {{"*",""},{"$",""}})

If Empty(cCorReceita)
   If _natua == 2
   	  U_ITMsg("[AOMS014] - Falha na consulta da Receita Federal.","Atenção",,1)
   Else 
      ConOut("[AOMS014] - Falha na consulta da Receita Federal.") 
   EndIf

   M->ZX_I_SITRF := " "
   M->ZX_I_DTSRF := " "
  
   M->ZX_SITST := " "
   M->ZX_DTST  := " "

   Return
EndIf 

If !(SubStr(cHdReceita,1,12) == "HTTP/1.1 200")
   
   If _natua == 2
   	  U_ITMsg("[AOMS014] - Falha na consulta da Receita Federal: ["+AllTrim(cHdReceita)+"]","Atenção",,1)
   Else 
      ConOut("[AOMS014] - Falha na consulta da Receita Federal: [ "+AllTrim(cHdReceita)+" ]") 
   EndIf

   M->ZX_I_SITRF := " "
   M->ZX_I_DTSRF := " "
  
   M->ZX_SITST := " "
   M->ZX_DTST  := " "

   Return


EndIf 

_lerrorec    := .F. 

_oJsonRec   := JsonObject():new()

_cRetRec := _oJsonRec:FromJson(cCorReceita) // FromJson(cCorSintegra)

// Verifica e formata resposta da Receita

If ! (ValType(_cRetRec) == "U") //!(SubStr(cHdReceita,1,12) == "HTTP/1.1 200" .And. (ValType(_cRetRec) == "U"))
     
    If _lisento //Se é isento e não achou na receita não atualiza 
    
       _lRet := .F.
       _lerro := .T.
       _cerro := cHdReceita
       
       	If _natua == 2
  	
       		U_ITMsg("Falha no webservice da receita, não há dados para atualizar","Atenção",cHdReceita,1)
       		
       		M->ZX_I_SITRF := " "
       		M->ZX_I_DTSRF := " "
  
       		M->ZX_SITST := " "
       		M->ZX_DTST  := " "
       		
       		Return
  		  		
  		EndIf
     	
    Else //Se não é isento usa os dados do sintegra no lugar dos dados da receita
    
    	_cReceita := _osintegra[1]
    	_lerrorec := .T.
    	
    	If _natua == 2
  	
       		U_ITMsg("Falha no webservice da receita, usando somente dados do sintegra","Atenção",cHdReceita,1)
  		  		
  		EndIf
    	
    
    EndIf

EndIf

_aNamesRec := _oJsonRec:GetNames()

_oReceita  := _oJsonRec:GetJsonObject("company")
_oReceita  := _oReceita[1]
_aNameComp := _oReceita:GetNames()

_cDtCriac := _oReceita:GetJsonObject("openingDate")

//===========================================================
// Se a razão social e nome reduzido estverem
// vazios, devem ser lidos da receita-federal.
// Pois não existem na CISP.
//===========================================================
If Empty(_cNome)
   _cNome := _oReceita:GetJsonObject("registeredName")
EndIf 

If Empty(_cNReduz)
   _cNReduz := _oReceita:GetJsonObject("name")
EndIf 

If SubStr(AllTrim(_cNReduz),1,1) == "*"
   _cNReduz := SubStr(_cNome,1,20) 
EndIf 
//===========================================================

_oRegSit   := _oReceita:GetJsonObject("register")
_aNameReg  := _oRegSit:GetNames()

_nI := aScan(_aNameReg, "status" )

If _nI > 0
   _cSituacRg := _oRegSit[_aNameReg[_nI]]
EndIf  

If Empty(_cDtCriac) 
   _nI := aScan(_aNameReg, "date" )

   If _nI > 0
      _cDtCriac := _oRegSit[_aNameReg[_nI]]
   EndIf  

EndIf

_nI := aScan(_aNamesRec, "updateDate" )
If _nI > 0
   _cDtAltRec := _oJsonRec[_aNamesRec[_nI]]
EndIf 

_oDoctosR := _oJsonRec:GetJsonObject("document")

_oBusiness := _oReceita:GetJsonObject("business")

_cCodNegoc   := ""
_cDesecNegoc := ""

If ValType(_oBusiness) <> "U"
   
   _oIndustri := _oBusiness:GetJsonObject("industries")

   For _nI := 1 To Len(_oIndustri)

       _aIndAtiva := _oIndustri[_nI]
	   _lIndAtiva := _oIndustri[_nI]:GetJsonObject("main")
	   If _lIndAtiva 
	      _cCodNegoc := _oIndustri[_nI]:GetJsonObject("code")
          _cDesecNegoc := _oIndustri[_nI]:GetJsonObject("description")
       EndIf 

   Next 

EndIf 

If _lisento  //Se é isento iguala dados da receita para sintegra
  
 	_CSINTEGRA := _oReceita
  	_CRECEITA := _oReceita
 
  	_asintegra := StrTokArr(cHdReceita,chr(10))
  	_areceita := StrTokArr(cHdReceita,chr(10))

   _aNameRece := _CRECEITA:GetNames()
  
   _oRegSit := _CRECEITA:GetJsonObject("register")
   _aNameReg  := _oRegSit:GetNames()

   _nI := aScan(_aNameReg, "status" )

   If _nI > 0
      _cSituacRg := _oRegSit[_aNameReg[_nI]]
   EndIf  

   _cDtAltRec := ""

   _nI := aScan(_aNamesRec, "updateDate" )
   If _nI > 0
      _cDtAltRec := _oJsonRec[_aNamesRec[_nI]]
   EndIf 

   _CRECSIT := _cSituacRg // _CRECEITA:situacaoCadastral 
   _CRECATU := _cDtAltRec // _CRECEITA:dataAtualizacao 
   _CRECCON := DToC(Date())     // _CRECEITA:dataConsulta 
  
Else
     
    _cinsco := M->ZX_INSCR 
    //Analisa resposta do sintegra e pega consulta habilitada igual à IE atual ou se não tiver pega última consulta habilitada 
    _csintegra := _osintegra // _osintegra[1]
    If _lerrorec
    	_CRECEITA := _csintegra
    Else
    	_CRECEITA := _oReceita
    EndIf

    _dmaior := Date() 

   _oRegSit := _CRECEITA:GetJsonObject("register")
   _aNameReg  := _oRegSit:GetNames()

   _nI := aScan(_aNameReg, "status" )

   If _nI > 0
      _cSituacRg := _oRegSit[_aNameReg[_nI]]
   EndIf  

   _csitmaior := Upper(_cSituacRg) 
   _nia := 0

EndIf

//=====================================================
// Obtem o endereço do Sintegra.
//=====================================================
If ValType(_CSINTEGRA) == "O" .Or. ValType(_CSINTEGRA) == "J"
   _aNameSint := _CSINTEGRA:GetNames()

   _nI := aScan(_aNameSint ,"address" )
   _cEndSint := ""

   If _nI > 0
      _cEndSint := _CSINTEGRA[_aNameSint[_nI]]	  
   EndIf 

   If _nI > 0
      _oEndSint := _cEndSint:GetJsonObject("state")
      _cUfSint  := _oEndSint:GetJsonObject("code")
      
      _cRua     := _cEndSint:GetJsonObject("line1")
      _cNumero  := _cEndSint:GetJsonObject("line2")
      _cCidade  := _cEndSint:GetJsonObject("city")
      _cCep     := _cEndSint:GetJsonObject("postalCode")
      _cComplem := _cEndSint:GetJsonObject("extension")
      _cBairro  := _cEndSint:GetJsonObject("district")
   EndIf 
EndIf 

//=====================================================
// Obtem o endereço do CISP Receita Federal
//=====================================================
_aNameRece := _CRECEITA:GetNames()

_nI := aScan(_aNameRece ,"address" )
_cEndRece := ""

If _nI > 0
   _cEndRece := _CRECEITA[_aNameRece[_nI]]	  
EndIf 

_oEndRece := _cEndRece:GetJsonObject("state")
_cUfRece  := _oEndRece:GetJsonObject("code")

If ! Empty(_cEndRece:GetJsonObject("line1"))
   _cRua     := _cEndRece:GetJsonObject("line1")
EndIf 

If ! Empty(_cEndRece:GetJsonObject("line2"))
   _cNumero  := _cEndRece:GetJsonObject("line2")
EndIf 

If ! Empty(_cEndRece:GetJsonObject("city"))
   _cCidade  := _cEndRece:GetJsonObject("city")
EndIf 

If ! Empty(_cEndRece:GetJsonObject("postalCode"))
   _cCep     := _cEndRece:GetJsonObject("postalCode")
EndIf 

If ! Empty(_cEndRece:GetJsonObject("extension"))
   _cComplem := _cEndRece:GetJsonObject("extension")
EndIf 

If ! Empty(_cEndRece:GetJsonObject("district"))
   _cBairro  := _cEndRece:GetJsonObject("district")
EndIf 

//Verifica se estado informado pela receita é igual ao informado pelo Sintegra
/* Validação desnecessária. Remover conforme solicitação do Agnaldo.
If _cUfSint <> _cUfRece // AllTrim(_CSINTEGRA:uf) != AllTrim(_CRECEITA:uf) 
  
  	U_ITMsg("UF indicada pelo Sintegra diverge da indicada pela Receita, consulta não será aplicada!","Atenção",,1)
  	M->ZX_INSCR := _cinsco
  	Return
  	
EndIf  
*/

_cRegiSint := ""
_cSituSint := ""

If Type("_aNameSint") == "A"
   _nI := aScan(_aNameSint ,{|x| x=="register"})

   If _nI > 0
      _cRegiSint := _CSINTEGRA[_aNameSint[_nI]]	  
      _cSituSint := _cRegiSint:GetJsonObject("status")
   EndIf 
EndIf 

_nI := aScan(_aNameRece ,{|x| x=="register"})
_cRegiRece := ""
_cSituRece := ""

If _nI > 0
   //_cRegiRece := _CSINTEGRA[_aNameRece[_nI]]
   _cRegiRece := _CRECEITA[_aNameRece[_nI]]	  
   _cSituRece := _cRegiRece:GetJsonObject("status")
EndIf 

_CSITSINTEGRA := Upper(_cSituSint) // AllTrim(_CSINTEGRA:situacaoCadastral)
_CRECSIT      := Upper(_cSituRece) // CRECEITA:situacaoCadastral
  
If  !(_CSITSINTEGRA == "HABILITADO" .Or. _CSITSINTEGRA == "HABILITADA" .Or. _CSITSINTEGRA == "ATIVO" .Or. _CSITSINTEGRA == "ATIVA" .OR.;
			_CSITSINTEGRA == "ATIVO - HABILITADO" .Or. _CSITSINTEGRA == "HABILITADO - ATIVO");
			.Or. !(AllTrim(_CRECSIT) == "HABILITADO" .Or. AllTrim(_CRECSIT) == "HABILITADA" .Or. AllTrim(_CRECSIT) == "ATIVA" .Or.  AllTrim(_CRECSIT) == "ATIVO" ;
			.Or. !AllTrim(_CRECSIT) == "ATIVO - HABILITADO" .Or. !AllTrim(_CRECSIT) == "HABILITADO - ATIVO" .Or. AllTrim(_CRECSIT) == "ERRO DE CONSULTA")
  	                                    
  		U_ITMsg("Existem restrições de cadastro no Sintegra e/ou Receita, consulta não será aplicada","Atenção",,1)
  		M->ZX_INSCR := _cinsco
  		Return
Else 
   _CRECSIT := "ATIVA" // Este campo tem dez posições. Para não gravar conteúdo truncado. Por exempo: "ATIVO - HA" ou "ATIVA - HA"
EndIf
  
If !Empty(AllTrim(M->ZX_INSCR))
  
  	M->ZX_CONTRIB := "1"
  	
EndIf

//=====================================================================
// Se a razão social da CISP-Receita estiver vazio, e do CISP-SINTEGRA 
// estiver vazio, pegar do CISP SINTEGRA.
//=====================================================================
If Empty(_cNome) .And. ! Empty(_cNomeSint)
   _cNome := _cNomeSint 
EndIf 

//=====================================================================
// Se o Nome Fantasia da CISP-Receita estiver vazio, e do CISP-SINTEGRA 
// estiver vazio, pegar do CISP SINTEGRA.
//=====================================================================
If Empty(_cNReduz) .And. ! Empty(_cNomeRSit)
   _cNReduz := _cNomeRSit
EndIf 

//=====================================================================
If !Empty(_cNome)
   M->ZX_NOME := _cNome 
EndIf 

If ! Empty(_cNReduz)
   M->ZX_NREDUZ := _cNReduz 
EndIf 

/*
_nI := aScan(_aNameSint ,{|x| x=="registeredName"})

If _nI > 0
   M->ZX_NOME := _CSINTEGRA[_aNameSint[_nI]]
EndIf 

If !Empty( _cRegiSint:GetJsonObject("name"))
  	M->ZX_NREDUZ := _cRegiSint:GetJsonObject("name") // _CRECEITA:nomeFantasia
EndIf
*/

//_nI := aScan(_aNameSint ,{|x| x=="address"})
//If _nI > 0
//   _oEndSint  := _CSINTEGRA[_aNameSint[_nI]] // _cRegiSint:GetJsonObject("address")
//EndIf 

If ! Empty( _cDtCriac )
    _cDtCriac := StrTran( _cDtCriac,"-","")
EndIf 

//If Empty(_cNrDocs)
//   _cNrDocs := 'ISENTO'
//EndIf

M->ZX_PAIS  := '105'

If ! Empty(_cNrDocs)
   M->ZX_INSCR := _cNrDocs  // IIf("inscricaoEstadual" $ cCorSintegra,AllTrim(_CSINTEGRA:inscricaoEstadual),"ISENTO")
EndIf 

If ! Empty(_cDtCriac)
   M->ZX_DTNASC := SToD(_cDtCriac)  // SToD(SubStr(AllTrim(_CRECEITA:dataAbertura),1,4)+SubStr(AllTrim(_CRECEITA:dataAbertura),6,2)+SubStr(AllTrim(_CRECEITA:dataAbertura),9,2))
EndIf 

If ! Empty(_cCodNegoc)
   //Valida se já tem cnae no CC3 e se não tiver inclui
   _ccnae := AllTrim(_cCodNegoc) // AllTrim(_CRECEITA:codigoAtividadeFiscal)
   _ccnae := SubStr(_ccnae,1,2) + SubStr(_ccnae,4,4) + "/" + SubStr(_ccnae,9,2) 
   CC3->(DBSetOrder(1))

   If !Empty(_ccnae) .And. !(CC3->(DBSeek(xFilial("CC3")+_ccnae)))
  
  	  CC3->(RecLock("CC3",.T.))
  	  CC3->CC3_COD := _ccnae
  	  CC3->CC3_DESC := _cDesecNegoc // AllTrim(_CRECEITA:descricaoAtividadeFiscal)
  	  CC3->(MSUnLock())
  	
   EndIf
 
   If ! Empty(_ccnae)
      M->ZX_I_END := _ccnae 
      M->ZX_I_DCNAE := _cDesecNegoc 
   EndIf

EndIf 

//--------------------------------------------
//_cUfRece  := _oEndRece:GetJsonObject("code")
//--------------------
//_cRua     := _cEndRece:GetJsonObject("line1")
//_cNumero  := _cEndRece:GetJsonObject("line2")
//_cCidade  := _cEndRece:GetJsonObject("city")
//_cCep     := _cEndRece:GetJsonObject("postalcode")
//_cComplem := _cEndRece:GetJsonObject("extension")
//_cBairro  := _cEndRece:GetJsonObject("district")
//--------------------------------------------

If Empty(_cUfRece) .And. ! Empty(_cUfSint)
   _cUfRece := _cUfSint
EndIf 

If !Empty(_cComplem) .And. !AllTrim(SubStr(_cComplem,1,1)) $ "*"
   _cComplem := ""
EndIf 

If Empty(AllTrim(_cNumero)) .And. Empty(AllTrim(_cComplem))
   If ! Empty(_cRua)
      M->ZX_END :=  AllTrim(_cRua) // _CSINTEGRA:endereco
   EndIf 
Else 
   If ! Empty(_cRua)
      M->ZX_END := AllTrim(AllTrim(_cRua) + ", " + AllTrim(_cNumero)+ " " + AllTrim(_cComplem))
   EndIf 
EndIf
  
If ! Empty(AllTrim(_cBairro)) // Empty(AllTrim(_CSINTEGRA:bairro))
   M->ZX_BAIRRO := _cBairro // AllTrim(_CSINTEGRA:bairro)
EndIf
  
If !(AllTrim(_cCep) == '99999999' .Or. AllTrim(_cCep) == '00000000')

  		//Testa se existe o Cep e se não tiver já inclui
  		ZA5->(DBSetOrder(1))
  		If ! (ZA5->(DBSeek(xFilial("ZA5")+AllTrim(_cCep)))) //(ZA5->(DBSeek(xFilial("ZA5")+AllTrim(StrZero(_CSINTEGRA:cep,8)))))
  		
  			//Separa tipo de logradouro de logradouro
  			_endere := AllTrim(_cRua) //AllTrim(_CSINTEGRA:endereco)
  			_ctiplog := ""
  			_clog := ""
  			_nposi := 1  //_cRua 
  			For _nnj := 1 to Len(AllTrim(_cRua)) // Len(AllTrim(_CSINTEGRA:endereco))
  			
  				If SubStr(_endere,_nnj,1) == " " .And. _nposi == 1
  					_nposi := 2
  				ElseIf _nposi == 1
  					_ctiplog += SubStr(_endere,_nnj,1)
  				ElseIf _nposi == 2
  					_clog += SubStr(_endere,_nnj,1)
  				EndIf 					
  			
  			Next
  		
  			ZA5->(RecLock("ZA5",.T.))
  			ZA5->ZA5_UF := _cUfRece // AllTrim(_CRECEITA:uf)
  			ZA5->ZA5_CEP := AllTrim(_cCep) // AllTrim(StrZero(_CSINTEGRA:cep,8))
  			ZA5->ZA5_TPLOG := _ctiplog
  			ZA5->ZA5_LOGRAD := _clog
  			ZA5->ZA5_BAIRRO := AllTrim(_cBairro) // AllTrim(_CSINTEGRA:bairro) 			
  			ZA5->(MSUnLock())
  			
  		EndIf

	  	If ! Empty(_cCep)	
  		   M->ZX_CEP := AllTrim(_cCep) // AllTrim(StrZero(_CSINTEGRA:cep,8))
		EndIf 
  	  			
EndIf

If ! Empty(_cUfRece)  
   M->ZX_EST := AllTrim(_cUfRece) // AllTrim(_CRECEITA:uf)
EndIf 

_CMUN := Posicione("CC2",4,xFilial("CC2")+M->ZX_EST+AllTrim(_cCidade),"CC2_CODMUN")
If !Empty(AllTrim(_cCidade)) .And. !Empty(AllTrim(_cmun))
   M->ZX_MUN := AllTrim(_cCidade) // AllTrim(_CSINTEGRA:cidade)
   M->ZX_CODMUN := _cmun
EndIf

If ! Empty(_CRECSIT)   
   M->ZX_I_SITRF := _CRECSIT
EndIf

M->ZX_I_DTSRF := DToC(DATE())

If ! Empty(_cSituacRg)
   M->ZX_SITST := AllTrim(_cSituacRg) // AllTrim(_CSINTEGRA:situacaoCadastral) 
EndIf 

M->ZX_DTST  := DToC(DATE())

//===============================================================================================================
//Consulta ao sistema Simpes Nacional
//===============================================================================================================

If ValType(oproc) = "O"
   oproc:cCaption := ("Consultando Simples...")
   ProcessMessages()
EndIf

//============================================
// >> Obtem os dados Link Simples Nacional. <<
//============================================

//Faz chamada ao webservice do Simples
CHdSimples  := ""
cCorSimples := HttpGet(cUrlsimples,"",NIL,aHeadOut,@cHdSimples)

//======================================================
// Descriptografia do JSon Recebido
//======================================================
_cDecodeTxt := ""
If ! Empty(cCorSimples)
	_cDecodeTxt := DecodeUTF8(cCorSimples, "cp1252")   
EndIf 

If ! Empty(_cDecodeTxt)
	cCorSimples := _cDecodeTxt
EndIf 

// Remover caracteres especiais do JSON.
cCorSimples := U_ITSUBCHR(cCorSimples, {{"*",""},{"$",""}})

_osimples   := nil

If ! Empty(cCorSimples)

   _oJsonSimp  := JsonObject():new()

   _cRetSimpl := _oJsonSimp:FromJson(cCorSimples) 

   _cSimpNcOp := ""
   _cSimplOpt := ""

   If ValType(_cRetSimpl) == "U"
      _aNamesSip := _oJsonSimp:GetNames()

      _oSimplNac := _oJsonSimp:GetJsonObject("company")
      If ValType(_oSimplNac) == "J" .Or. ValType(_oSimplNac) == "A"
	     If Len(_oSimplNac) > 0 
            _oSimplNac := _oSimplNac[1]     
            _cSimplNac := _oSimplNac:GetJsonObject("business")
            _cSimplOpt := _cSimplNac:GetJsonObject("taxSystem")
            _cSimpNcOp := _cSimplOpt:GetJsonObject("statusSimplesNacional")
		 Else 
            _cSimpNcOp := "NAO OPTANTE" // JSON RETORNADO SEM INFORMAÇÕES.      
		 EndIf 
      EndIf
   EndIf

   If ! Empty(_cSimpNcOp)
      _cSimpNcOp := Upper(_cSimpNcOp)
   EndIf 
EndIf 

//Verifica e formata resposta do Simples
If ! Empty(cCorSimples) .And. SubStr(cHdSimples,1,12) == "HTTP/1.1 200" .And. ValType(_cRetSimpl) == "U" //FWJsonDeserialize(cCorSimples,@_osimples) 
   If Type("_cSimpNcOp") == "C" .And. SubStr(AllTrim(_cSimpNcOp),1, 7) == "OPTANTE"
	  _catusimples := '1'
   Else
   	  _catusimples := '2'
   EndIf
Else
   _catusimples := '2'
EndIf
  	  		
M->ZX_SIMPNAC := _catusimples
  
//Gravação de defaults nos campos mais usados
If Empty(M->ZX_I_RISCO)
   M->ZX_I_RISCO := "B"
EndIf

If Empty(M->ZX_I_GRPVE)
   M->ZX_I_GRPVE  := '999999'
EndIf

If u_itgetmv("ITDTPROS","1225") >= SubStr(DToS(DATE()),5,4)
   If Empty(M->ZX_I_VENCL)
	  M->ZX_I_VENCL := SToD(SubStr(DToS(date()),1,4)+"1231")
   EndIf
Else
   If Empty(M->ZX_I_VENCL)
	  M->ZX_I_VENCL := SToD(SubStr(DToS(date()+365),1,4)+"1231")
   EndIf
EndIf   
  
Return 

/*
===============================================================================================================================
Programa----------: AOMS014K
Autor-------------: Josué Danich
Data da Criacao---: 16/04/2013
Descrição---------: Consulta Cisp via browse
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS014K()

Local oproc

If Empty(AllTrim(SZX->ZX_SITST)) .Or. Empty(SZX->ZX_END) 

   If U_ITMsg("Atualiza prospect com dados de consulta Cisp?","Atenção",,2,2,2)
	
      regtomemory("SZX")
      FWMsgRun(,{|oproc| U_AOMS014B(2,oproc)},"Aguarde...","Aguarde")
		
      //Grava alteração
      u_itmemtor("SZX")

	  U_ITMsg("Atualização do Prospect com os dados da Cisp concluído.","Atenção",,2)
		
   EndIf
	
Else

	U_ITMsg("Registro já foi atualizado via Cisp","Atenção",,1)

EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS014C
Autor-------------: Josué Danich
Data da Criacao---: 16/04/2013
Descrição---------: Consulta Cisp via browse
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS014C()

	FWMsgRun(,{ || U_TelCred(1)}, "Aguarde...","Realizando consulta Cisp...")

Return

/*
===============================================================================================================================
Programa----------: AOMS014V
Autor-------------: Josué Danich
Data da Criacao---: 29/08/2018
Descrição---------: Valida se cnpj já está cadastrado na base
Parametros--------: _ccnpj - cnpj a ser testado
Retorno-----------: _lRet - validação de existência
===============================================================================================================================
*/
Static Function AOMS014V(_ccnpj)

Local _lRet := .F.

SA1->(DBSetOrder(3))
If SA1->(DBSeek(xFilial("SA1")+AllTrim(_ccnpj)))

	_lRet := .T.
	U_ITMsg("CNPJ já está cadastrado como cliente!","Atenção","Cliente: " + SA1->A1_COD + "/" + SA1->A1_LOJA + " - " + SA1->A1_NOME,1)
	
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS014D
Autor-------------: Julio de Paula Paz
Data da Criacao---: 04/09/2019
Descrição---------: Função responsável por exibir a janela para a digitação dos endereços de email, assunto, mensagem
Parametros--------: _cAnexo		- Endereço do arquivo anexo
------------------: _cEmail		- Endereço de E-mail para qual será enviado a mensagem
------------------: _cCc		- Endereço de E-mail que está no campo Com Cópia
------------------: _cAssunto	- Assunto do E-mail
------------------: _cMens		- Mensagem de texto para o corpo do E-mail
------------------: cMailCom    - Email de remetente
Retorno-----------: _lRet == .T. = E-mail enviado
                             .F. = Envio de E-mail cancelado.
===============================================================================================================================
*/
User Function AOMS014D(_cAnexo,_cEmail,_cCc,_cAssunto,_cMens,cMailCom)

Local oAssunto
Local oButCan
Local oButEnv
Local oCc

Local oGetAssun
Local oGetCc

Local oGetPara
Local oMens
Local oPara

Local _csetor := ""

Local _aConfig	:= U_ITCFGEML('')
Local _cEmlLog	:= ""
Local cHtml		:= ""
Local nOpcA		:= 2

Local cGetAssun	:= _cAssunto
Local cGetCc	:= _cCc
Local cGetPara	:= _cEmail + Space(80)
Local _lRet     := .F.

Private oDlgMail , _oFont


If (Len(PswRet()) # 0) // Quando nao For rotina automatica do configurador

	_csetor	:= AllTrim(PswRet()[1][12])		// Pega departamento do usuario
   
EndIf


If Empty(AllTrim(_csetor))
 
 	_csetor := "Crédito"
 	
EndIf

cHtml := 'Prezados(as), '
cHtml += '<br><br>'
cHtml += 'Pedimos a gentileza de enviar-nos as solicitações abaixo: <br>'
cHtml += '<br><br>'
cHtml += '<table>'
cHtml += '   <tr>'
cHtml += '     <td> Cliente:</th>'
cHtml += '     <td>' + AllTrim(SZX->ZX_NOME) + '</th>'
cHtml += '   </tr>'
cHtml += '   <tr>'
cHtml += '     <td> CNPJ: </td>'
cHtml += '     <td> ' + Transform(SZX->ZX_CGC,"@R! NN.NNN.NNN/NNNN-99") + '</td>'
cHtml += '   </tr>'
cHtml += '   <tr>'
cHtml += '     <td> Municipio: </td>'
cHtml += '     <td> ' + RETFIELD("CC2",1,xFilial("CC2")+SZX->ZX_EST+SZX->ZX_CODMUN,"CC2_MUN") + '</td>'
cHtml += '   </tr>'
cHtml += '   <tr>'
cHtml += '     <td> Estado: </td>'
cHtml += '     <td> ' + SZX->ZX_EST + '</td>'
cHtml += '   </tr>'
cHtml += '   <tr>'
cHtml += '     <td> DDD: </td>'
cHtml += '     <td> ' + SZX->ZX_DDD + '</td>'
cHtml += '   </tr>'
cHtml += '   <tr>'
cHtml += '     <td> Telefone: </td>'
cHtml += '     <td> ' + SZX->ZX_TEL + '</td>'
cHtml += '   </tr>'
cHtml += '   <tr>'
cHtml += '     <td> E-mail: </td>'
cHtml += '     <td> ' + SZX->ZX_EMAIL + '</td>'
cHtml += '   </tr>'
cHtml += '</table> 
cHtml += '<br><br>'
cHtml += 'Sem mais e a disposição.'
cHtml += '<br><br>'

cHtml += '<table class=MsoNormalTable border=0 cellpadding=0>'
cHtml += '<tr>'
cHtml +=     '<td style="padding:.75pt .75pt .75pt .75pt">'
cHtml +=         '<p class=MsoNormal align=center style="text-align:center">'
cHtml +=             '<b><span style="font-size:18.0pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">'+ Capital( AllTrim( UsrFullName( RetCodUsr() ) ) ) +'</span></b>'
cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
cHtml +=     '</td>'
cHtml +=     '<td style="background:#A2CFF0;padding:.75pt .75pt .75pt .75pt">&nbsp;</td>'
cHtml +=     '<td style="padding:.75pt .75pt .75pt .75pt">
cHtml +=         '<table class=MsoNormalTable border=0 cellpadding=0>'
cHtml +=              '<tr>'
cHtml +=                  '<td style="padding:.75pt .75pt .75pt .75pt">'
cHtml +=                      '<p class=MsoNormal><b><span style="font-size:13.5pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#6FB4E3;mso-fareast-language:PT-BR">' + _cSetor + '</span></b>'
cHtml +=                      '<b><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></b>
cHtml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"><br></span>
cHtml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
cHtml +=                  '</td>'
cHtml +=              '</tr>'
cHtml +=              '<tr>'
cHtml +=                  '<td style="padding:.75pt .75pt .75pt .75pt">
cHtml +=                      '<p class=MsoNormal><span style="font-size:12.0pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">Tel: ' + Posicione("SY1",3,xFilial("SY1") + RetCodUsr(),"Y1_TEL") + '</span>'
cHtml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
cHtml +=                  '</td>'
cHtml +=              '</tr>'
cHtml +=         '</table>'
cHtml +=     '</td>'
cHtml += '</tr>'
cHtml += '</table>'
cHtml += '<table class=MsoNormalTable border=0 cellpadding=0 width=437 style="width:327.75pt">'
cHtml +=     '<tr>'
cHtml +=         '<td style="padding:.75pt .75pt .75pt .75pt">'
cHtml +=             '<p class=MsoNormal align=center style="text-align:center">'
cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR">'
cHtml +=                 '<img width=400 height=51 src="http://www.italac.com.br/assinatura-italac/images/marcas-goiasminas-industria-de-laticinios-ltda.jpg">'
cHtml +=             '</span>
cHtml +=             '</p>'
cHtml +=         '</td>'
cHtml +=     '</tr>'
cHtml += '</table>'
cHtml += '<p class=MsoNormal><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';display:none;mso-fareast-language:PT-BR">&nbsp;</span></p>'
cHtml += '<table class=MsoNormalTable border=0 cellpadding=0>'
cHtml +=     '<tr>'
cHtml +=         '<td style="padding:.75pt .75pt .75pt .75pt">'
cHtml +=             '<p class=MsoNormal align=center style="text-align:center">'
cHtml +=             '<b><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">Política de Privacidade </span></b>'
cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
cHtml +=             '<p class=MsoNormal style="mso-margin-top-alt:auto;mso-margin-bottom-alt:auto;text-align:justify">'
cHtml +=             '<span style="font-size:7.5pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">
cHtml +=                 'Esta mensagem é destinada exclusivamente para fins profissionais, para a(s) pessoa(s) a quem For dirigida, podendo conter informação confidencial e legalmente privilegiada. '
cHtml +=                 'Ao recebê-la, se você não For destinatário desta mensagem, fica automaticamente notificado de abster-se a divulgar, copiar, distribuir, examinar ou, de qualquer forma, utilizar '
cHtml +=                 'sua informação, por configurar ato ilegal. Caso você tenha recebido esta mensagem indevidamente, solicitamos que nos retorne este e-mail, promovendo, concomitantemente sua '
cHtml +=                 'eliminação de sua base de dados, registros ou qualquer outro sistema de controle. Fica desprovida de eficácia e validade a mensagem que contiver vínculos obrigacionais, expedida '
cHtml +=                 'por quem não detenha poderes de representação, bem como não esteja legalmente habilitado para utilizar o referido endereço eletrônico, configurando falta grave conforme nossa '
cHtml +=                 'política de privacidade corporativa. As informações nela contidas são de propriedade da Italac, podendo ser divulgadas apenas a quem de direito e devidamente reconhecido pela empresa.'
cHtml +=             '</span>'
cHtml +=             '<span style="font-size:7.5pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>'
cHtml +=         '</td>'
cHtml +=     '</tr>
cHtml += '</table>'

DEFINE MSDIALOG oDlgMail TITLE "E-Mail" FROM 000, 000  TO 415, 584 COLORS 0, 16777215 PIXEL

	//======
	// Para:
	//======
	@ 005, 006 Say oPara PROMPT "Para:" SIZE 015, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
	@ 005, 030 MSGET oGetPara VAR cGetPara SIZE 256, 010 OF oDlgMail PICTURE "@x" COLORS 0, 16777215 PIXEL

	//===========
	// Com cópia:
	//===========
	@ 021, 006 Say oCc PROMPT "Cc:" SIZE 015, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
	@ 021, 030 MSGET oGetCc VAR cGetCc SIZE 256, 010 OF oDlgMail PICTURE "@x" COLORS 0, 16777215 PIXEL

	//=========
	// Assunto:
	//=========
	@ 037, 006 Say oAssunto PROMPT "Assunto:" SIZE 022, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
	@ 037, 030 MSGET oGetAssun VAR cGetAssun SIZE 256, 010 OF oDlgMail PICTURE "@x" COLORS 0, 16777215 PIXEL

	//==========
	// Mensagem:
	//==========
	@ 069, 006 Say oMens PROMPT "Mensagem:" SIZE 030, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
	_oFont		:= TFont():New( 'Courier new' ,, 12 , .F. )
	_oScrAux	:= TSimpleEditor():New( 080 , 006 , oDlgMail , 285 , 105 ,,,,, .T. )
	_oScrAux:TextFormat(1)
	_oScrAux:Load( cHtml )
    _cHtml:=cHtml
		
	@ 189, 201 BUTTON oButEnv PROMPT "&Enviar"		SIZE 037, 012 OF oDlgMail ACTION ( nOpcA := 1 , cHtml := _oScrAux:RetText() , oDlgMail:End() ) PIXEL
	@ 189, 245 BUTTON oButCan PROMPT "&Cancelar"	SIZE 037, 012 OF oDlgMail ACTION ( nOpcA := 2 , oDlgMail:End() ) PIXEL

ACTIVATE MSDIALOG oDlgMail CENTERED

If nOpcA == 1
   If Empty(cHtml) .Or. cHtml = NIL
      cHtml:=_cHtml
   EndIf
   U_ITENVMAIL( Lower(AllTrim(UsrRetMail(RetCodUsr()))), cGetPara, cGetCc, cMailCom, cGetAssun, cHtml, , _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )
   
   _lRet := "SUCESSO" $ Upper(_cEmlLog)
   U_ITMsg( _cEmlLog+CHR(13)+CHR(10)+"E-mail para: "+AllTrim(cGetPara) , "Atenção!" ,"CC: "+cGetCc,3 )


Else
	U_ITMsg( 'Envio de e-mail cancelado pelo usuário.' , 'Atenção!' , ,1 )
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS014F
Autor-------------: Julio de Paula Paz
Data da Criacao---: 04/09/2019
Descrição---------: Função utilizada no botão de legenda mostrar o significado de cada cor.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS014F()

Local cCadastro:=OemToAnsi("Efetivação do Cadastro de Prospect")

BrwLegenda(cCadastro,"Legenda",{	{"BR_VERDE", "Análise efetuada"},;
	                                {"BR_VERMELHO","Falta grupo de vendas,risco de crédito e observação..."},;
									{"BR_AZUL","E-mail enviado"}})

Return

/*
===============================================================================================================================
Programa----------: AOMS014G
Autor-------------: Julio de Paula Paz
Data da Criacao---: 04/09/2019
Descrição---------: Função de envio de e-mail na Efetivação do cadastro de prospect.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS014G()
Local _cEmail := ""
Local _cCC := " "
Local _cMailcom := " " 
Local _cAssunto := ""
Local _cCoord, _cGeren, _cSuper, _cEmailGer

Begin Sequence
   //Envia email de Informações Comerciais
   _cEmail := Posicione("SA3",1,xFilial("SA3")+SZX->ZX_VEND,"A3_EMAIL") //Email do representante responsável pelo pedido
   _cCoord := Posicione("SA3",1,xFilial("SA3")+SZX->ZX_VEND,"A3_SUPER")
   _cGeren := Posicione("SA3",1,xFilial("SA3")+SZX->ZX_VEND,"A3_GEREN")
   _cSuper := Posicione("SA3",1,xFilial("SA3")+SZX->ZX_VEND,"A3_I_SUPE")
   _cCC := " "

   _cEmailGer := ""	
   If !Empty(_cSuper)
      _cEmailGer := Posicione("SA3",1,xFilial("SA3")+_cSuper,"A3_EMAIL")
   EndIf

   If ! Empty(_cEmailGer)
      _cCC += AllTrim(_cEmailGer) + ";"
   EndIf

   _cEmailGer := ""
   If !Empty(_cCoord)
      _cEmailGer := Posicione("SA3",1,xFilial("SA3")+_cCoord,"A3_EMAIL")
   EndIf

   If ! Empty(_cEmailGer)
      _cCC += AllTrim(_cEmailGer) + ";"
   EndIf
   
   _cEmailGer := ""
   If !Empty(_cGeren)
      _cEmailGer := Posicione("SA3",1,xFilial("SA3")+_cGeren,"A3_EMAIL") 
   EndIf

   If ! Empty(_cEmailGer)
      _cCC += AllTrim(_cEmailGer) + ";"
   EndIf
   
   _cMailcom := " " 
   _cAssunto := "Informações comerciais e documentação do cliente: CNPJ " + Transform(SZX->ZX_CGC,"@R! NN.NNN.NNN/NNNN-99") + " -  NOME: " + SZX->ZX_NOME
  			
   If U_AOMS014D(,_cEmail,_cCC,_cAssunto,,_cMailcom)
      SZX->(RecLock("SZX",.F.))
      SZX->ZX_I_ENVML := "S"
      SZX->(MSUnLock())
   EndIf

End Sequence

Return

/*
===============================================================================================================================
Programa----------: AOMS014W
Autor-------------: Julio de Paula Paz
Data da Criacao---: 26/07/2023
Descrição---------: Validar preenchimento de dados na tela do Prospect.
Parametros--------: _cValid = Validador a ser rodado
Retorno-----------: _lRet = .T. Validação Ok / .F. = Falha na validação.
===============================================================================================================================
*/
User Function AOMS014W(_cValid)
Local _lRet := .T.
Local _cRaizCnpj := SubStr(SZX->ZX_CGC,1,8)
Local _nLimiteCr := 0 

Begin Sequence 
   If _cValid == "CREDITO"
      SA1->(DBSetOrder(17)) // H = Str(A1_CGC,1,8) // Raiz CNPJ
	  If SA1->(MsSeek(_cRaizCnpj))
	     While ! SA1->(Eof()) .And. SubStr(SA1->A1_CGC,1,8) == _cRaizCnpj
            
			If SA1->A1_MSBLQL == "2" .And. SA1->A1_LC > 0 .And. DToS(SA1->A1_VENCLC) >= DToS(Date())
               _nLimiteCr := SA1->A1_LC
               Exit
			EndIf 

            SA1->(DBSkip())
		 EndDo

         If _nLimiteCr > 0 .And. SZX->ZX_I_LC > 0 
            U_ITMsg("Já existe um grupo de clientes cadastrado com a mesma raiz de CNPJ, e com Limite de Crédito informado no valor de: "+AllTrim(Str(_nLimiteCr,16,2)),"Atenção!","O limte de crédito informado no Prospect deve ser zerado.",1)
            _lRet := .F.
			Break
		 EndIf 
         
		 _lConsdBrk := .T.  // Quando True considera os valores de limite de crédito do Broker. Quando False considera o limite de crédito do cadastro de clientes.

		 SA3->(DBSetOrder(1)) 
	     If SA3->(MsSeek(xFilial("SA3")+SZX->ZX_VEND))
            If SA3->A3_I_VBROK == 'B' .And. SA3->A3_I_LC > 0 .And. _nLimiteCr >0
               U_ITMsg("Este cliente é um Broker e já existe um grupo de clientes cadastrado com a mesma raiz de CNPJ, e com Limite de Crédito informado no valor de: "+AllTrim(Str(_nLimiteCr,16,2)),"Atenção!","O limte de crédito do Broker não será considerado na efetivação do prospect.",1)
			   _lConsdBrk := .F.
			   Break
            EndIf 
		 EndIf 

		 If _nLimiteCr > 0 .And. SZX->ZX_I_LC == 0
		    _lRet := .T.
			Break 
		 EndIf 
      EndIf 

      _lConsdBrk := .T.  // Quando True considera os valores de limite de crédito do Broker. Quando False considera o limite de crédito do cadastro de clientes.
      SA3->(DBSetOrder(1)) 
	  If SA3->(MsSeek(xFilial("SA3")+SZX->ZX_VEND))
         If ! (SA3->A3_I_VBROK == 'B' .And. SA3->A3_I_LC > 0)
	        _lConsdBrk := .F.           
         EndIf 
	  EndIf 

	  If SZX->ZX_I_LC == 0 .And. ! _lConsdBrk
         U_ITMsg("O limite de crédito deste cliente precisa ser informado.","Atenção!","Informe um limite de crédito para este cliente.",1)
         _lRet := .F.
		 Break 
	  EndIf 
   EndIf 

End Sequence 

Return _lRet
