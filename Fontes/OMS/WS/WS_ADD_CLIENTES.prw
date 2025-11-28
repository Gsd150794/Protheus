/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer | 16/02/2020 | Chamado 33016. Gravacao do campo ZX_TIMEEMI com FWTimeStamp( 4, DATE(), Time() )
Alex Wallauer | 30/03/2021 | Chamado 36221. Ajustes na leitura dos dados de contato e do SLC
Lucas Borges  | 22/04/2025 | Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
===============================================================================================================================
 Analista     - Programador  - Inicio   - Envio    - Chamado - Motivo da Alteração
====================================================================================================================================================================================
Jerry         - Julio Paz    - 07/04/25 - 10/04/25 - 44503   - Inclusão de nova tag Segmento do cliente e atualização do cadastro de clientes e portal de vandas.
Antonio       - Julio Paz    - 29/10/25 - 30/10/25 - 52463   - Formatação da informação CNAE (ZX_I_END/A1_CNAE), em algumas integrações esta informação está vindo sem formatação.
====================================================================================================================================================================================

*/                                        
//====================================================================================================
// Definicoes de Includes da Rotina
//====================================================================================================
#Include "TOTVS.ch"
#Include 'apwebsrv.ch'
#Include 'TbiConn.ch'

/*
===============================================================================================================================
Programa----------: AddCliente
Autor-------------: TOTVS
Data da Criacao---: n/a
Descrição---------: Integração de Clientes
Parametros--------: XML
Retorno-----------: Grava o Cliente
===============================================================================================================================
*/

WSSTRUCT tAdContatoDet

	WSDATA   CONTATODW		AS string // código do contato na DW
	WSDATA   CONTATOPRT		AS string OPTIONAL // código do contato no Protheus
	WSDATA   CONTATONOME	AS string // contato
	WSDATA   CONTATODDD		AS string OPTIONAL
	WSDATA   CONTATOCELULAR	AS string OPTIONAL
	WSDATA   CONTATOFONE	AS string OPTIONAL // telefone
	WSDATA   CONTATOEMAIL	AS string OPTIONAL // email
	WSDATA   CONTATOFUNCAO	AS string OPTIONAL // cargo
	WSDATA   CONTATOSTATUS	AS string OPTIONAL //

ENDWSSTRUCT

WSSTRUCT tAdContatoCab

	WSDATA zzItensDoContato		AS Array Of tAdContatoDet OPTIONAL

ENDWSSTRUCT
//===========================================================================================================================
//

WSSERVICE WANW002 DESCRIPTION "Serviço de atualização dos Clientes"// NAMESPACE "http://local.com.br/"

	WSDATA   EMPRESA           	AS string OPTIONAL// cnpj
	WSDATA   FILIAL            	AS string OPTIONAL// cnpj
	WSDATA   CNPJ             	AS string // cnpj
	WSDATA   RAZAOSOCIAL        AS string //razao_social
	WSDATA   NOMEFANTASIA       AS string // nome_fantasia
	WSDATA   INSESTADUAL        AS string // inscricao_estadual
	WSDATA   INSMUNICIPAL       AS string OPTIONAL // inscricao_municipal
	WSDATA   INSRURAL           AS string OPTIONAL // inscricao_rural
	WSDATA   DATANASC			AS date OPTIONAL // data_fundacao
	WSDATA   HOMEPAGE           AS string OPTIONAL // site
	WSDATA   TIPO             	AS string // tipo
	WSDATA   DDD                AS string
	WSDATA   TELEFONE           AS string // telefone_geral_1
	WSDATA   TELFAX             AS string OPTIONAL // telefone_geral_2
	WSDATA   EMAIL              AS string // email_nfe
	WSDATA   CEP             	AS string // endereco_cep
	WSDATA   ENDERECO           AS string // endereco_rua
	WSDATA   NUMERO             AS string // endereco_numero
	WSDATA   BAIRRO             AS string // endereco_bairro
	WSDATA   COMPLEMENTO        AS string OPTIONAL // endereco_complemento
	WSDATA   OBSERVACAO         AS string OPTIONAL // observacao
	WSDATA   VENDEDOR           AS string // vendedor_codigo
	WSDATA   DATACADASTRO		AS date // data_cadastro
	WSDATA   HORACADASTRO       AS string // hora_cadastro
	WSDATA   SUFRAMA            AS string OPTIONAL // suframa
	WSDATA   RGFISICA           AS string OPTIONAL // rg
	WSDATA   ESTADO             AS string // estado_codigo_ibge
	WSDATA   CODMUNICIPIO       AS string // municipio_codigo_ibge
	WSDATA   FISICAJURIDICA     AS string // fisica_juridica
	WSDATA   CNAE	            AS string OPTIONAL // cnae
	WSDATA   SEGMENTO     		AS string // OPTIONAL// Segmento
	WSDATA   COND               AS string   //Cond de Pagamento
	WSDATA   GRUPOVENDA			AS string  // Grupo de Vendas
	WSDATA   TRANSPORTADORA		AS string // Transportadora
	WSDATA 	 NUMERODW			AS String // codigo   
	WSDATA 	 CCHEP  			AS String OPTIONAL // CHEP
	WSDATA 	 LC    			    AS float OPTIONAL // LC
	WSDATA 	 TADCONTATO			AS tAdContatoCab OPTIONAL

	// Retorno do WEBSERVICE
	WSDATA AtualCliente		AS String

	WSMETHOD AddCliente		DESCRIPTION "Inclusao/Atualizacao de Cliente - SA1"

ENDWSSERVICE

//============================================================================================================================
//

/*WSMETHOD AddCliente WSRECEIVE Empresa, Filial, Cnpj, Razaosocial, Nomefantasia, Insestadual, Insmunicipal, Insrural, Datanasc,;
 Homepage, Tipo, Ddd, Telefone, Telfax, Email, Cep, Endereco, Numero, Bairro, Complemento,Observacao,  Vendedor,;
 Datacadastro,  Horacadastro, Suframa, Rgfisica,Estado,Codmunicipio,Cepentrega, Estentrega,Munentrega,;
 Bairroentrega,Endentrega, Numentrega, Complentrega, Fisicajuridica, Cnae, Segmento, Cond, GrupoVenda, Transportadora, Numerodw, TADCONTATO WSSEND AtualCliente WSSERVICE WANW002
*/

WSMETHOD AddCliente WSRECEIVE Empresa, Filial, Cnpj, Razaosocial, Nomefantasia, Insestadual, Insmunicipal, Insrural, Datanasc,;
 Homepage, Tipo, Ddd, Telefone, Telfax, Email, Cep, Endereco, Numero, Bairro, Complemento,Observacao,  Vendedor,;
 Datacadastro,  Horacadastro, Suframa, Rgfisica,Estado,Codmunicipio,;
 Fisicajuridica, Cnae, Segmento, Cond, GrupoVenda, Transportadora, Numerodw, cchep, lc , tadcontato WSSEND AtualCliente WSSERVICE WANW002

Local aVetor	:= {}
Local cCnpj			:= AllTrim(UnMaskCNPJ(::CNPJ))
Local cRazaosocial	:= Upper(AllTrim(::Razaosocial))
Local cNomefantasia	:= Upper(AllTrim(::Nomefantasia))
Local cInsestadual	:= Upper(AllTrim(::Insestadual))
Local cInsmunicipal	:= Upper(AllTrim(::Insmunicipal))
Local cInsrural		:= Upper(AllTrim(::Insrural))
Local dDatanasc		:= ::Datanasc
Local cHomepage		:= Upper(AllTrim(::Homepage))
Local cTipo			:= Upper(AllTrim(::Tipo))
Local cDdd			:= Upper(AllTrim(::Ddd))
Local cTelefone		:= Upper(AllTrim(::Telefone))
Local cTelfax		:= Upper(AllTrim(::Telfax))
Local cEmail		:= Upper(AllTrim(::Email))
Local cCep			:= Upper(AllTrim(::Cep))
Local cEndereco		:= Upper(AllTrim(::Endereco)) + ", " + Upper(AllTrim(::Numero))
Local cBairro		:= Upper(AllTrim(::Bairro))
Local cComplemento	:= Upper(AllTrim(::Complemento))
Local cObservacao	:= Upper(AllTrim(::Observacao))
Local cVendedor		:= Upper(AllTrim(::Vendedor))
Local dDatacadastro	:= ::Datacadastro
Local cHoracadastro	:= Upper(AllTrim(::Horacadastro))
Local cSuframa		:= Upper(AllTrim(::Suframa))
Local cRgfisica		:= Upper(AllTrim(::Rgfisica))
Local cEstado		:= Upper(AllTrim(::Estado))
Local cCodmunicipio	:= Upper(AllTrim(::Codmunicipio))
Local cFisicajuridica	:= Upper(AllTrim(::Fisicajuridica))
Local cCnae			:= Upper(AllTrim(::Cnae))
Local cSubSegmen	:= Upper(AllTrim(::Segmento)) 
Local cSegmento		:= SubStr(cSubSegmen,1,2)     
Local cCond	     	:= Upper(AllTrim(::Cond))
Local cGrupoVenda	:= Upper(AllTrim(::GrupoVenda))
Local cTransportadora:= Upper(AllTrim(::Transportadora))
Local cNumerodw		:= AllTrim(::Numerodw)
Local cContato      := Upper(AllTrim(::TADCONTATO))
Local cCCHEP        := Upper(AllTrim(::cchep))
Local nLC           := ::lc
Local _lProspct     := U_ITGETMV("IT_INTPROSP",.F.) 
Local cCodigo	:= ""
Local cLoja		:= ""
Local aRecnoSM0	:= {}
Local cEmprWan	:= Upper(AllTrim(::Empresa))
Local cFilWan	:= Upper(AllTrim(::Filial))
Local lEmpres	:= .F.
Local nOpc		:= 0

Local lRet		:= .T.
Local cRaizCNPJ	:= ""
Local nTamCdCli	:= 0

// iniciando-se os trabalhos
U_ITConOut("[WS_ADD_CLIENTE] "+Repl("-",150))
U_ITConOut("[WS_ADD_CLIENTE] WebService Cliente")
U_ITConOut("[WS_ADD_CLIENTE] Numero DW: " + cNumeroDw + " Dados Contato " + cContato)

Private lMsHelpAuto		:= .T.
Private lAutoErrNoFile	:= .T.
Private lMsErroAuto		:= .F.
Private aAutoErro		:= {}


// tratamento para carregar a empresa diretamente no fonte
aRecnoSM0	:=	{cEmprWan,cFilWan} //Posição 1 referente ao codigo da empresa, posição 2 referente a filial caso não seja informado no aParam
If !Empty(AllTrim(aRecnoSM0[01])) .And. !Empty(AllTrim(aRecnoSM0[02]))
     Reset Environment
     RPCSetType(3)
     If FindFunction("WFPREPENV")
          WfPrepENV(aRecnoSM0[1],aRecnoSM0[2])
          lAuto	:=	.T.
     Else
          Prepare Environment Empresa aRecnoSM0[1] Filial aRecnoSM0[2]
     EndIf
     lEmpres := .T.
EndIf

begintran()

nTamCdCli := TamSX3("A1_COD")[1]
// primeiro valido o CNPJ. Se ele não existir, incluo. Caso contrário não rejito, pois pode ter alteração de contatos.
// Valido a existência do CNPJ
DBSelectArea("SA1")
DBSetOrder(3)
If !DBSeek(xFilial("SA1") + cCNPJ)
	//Valido a Existência do ID do cliente na base
	If FChkIdDW(cNumeroDw,"SA1")
		_cMsgErro	:= "Cliente DW [" + cNumeroDw + "] ja existe na base com outro CNPJ."
		_cObs := "ERRO:" + _cMsgErro
		SetSoapFault("Retorno",LEFT(_cObs,60))
		U_ITConOut(_cObs)
		::AtualCliente := "[FALSO] Erro ao realizar a atualizacao do Cliente " + _cObs
		lRet := .F.
	EndIf

	If _lProspct .And. FChkIdDW(cNumeroDw,"SZX")
		_cMsgErro	:= "Cliente DW [" + cNumeroDw + "] ja existe na base com outro CNPJ."
		_cObs := "ERRO:" + _cMsgErro
		SetSoapFault("Retorno",LEFT(_cObs,60))
		U_ITConOut(_cObs)
		::AtualCliente := "[FALSO] Erro ao realizar a atualizacao do Cliente " + _cObs
		lRet := .F.
	EndIf

	// Valido o tipo do cliente
	If !(cTipo $ "FLRSX")
		_cMsgErro	:= "Tipo do cliente DW nao esta dentro dos parametros esperados: F=Cons.Final;L=Produtor Rural;R=Revendedor;S=Solidario;X=Exportacao"
		_cObs := "ERRO:" + _cMsgErro
		SetSoapFault("Retorno",LEFT(_cObs,60))
		U_ITConOut(_cObs)
		::AtualCliente := "[FALSO] Erro ao realizar a atualizacao do Cliente " + _cObs
		lRet := .F.
	EndIf

    SA3->( DBSetOrder(1) )
    If !SA3->( DBSeek( xFilial('SA3') +cVendedor ) )
		_cMsgErro:= "Vendedor do Cleinte DW não encontrado no Protheus: "+cVendedor
		_cObs    := "ERRO:" + _cMsgErro
		SetSoapFault("Retorno",LEFT(_cObs,60))
		U_ITConOut(_cObs)
		::AtualCliente := "[FALSO] Erro ao realizar a atualizacao do Cliente " + _cObs
		lRet := .F.
	EndIf


	If lRet
		nOpc := 3 // Inclusao
		// Tratamento de variaveis locais
		cPessoa		:= IIf(Len(cCNPJ) < 14,"F","J")
		cFisicajuridica	:= cPessoa
		cRaizCNPJ	:= SubStr(cCNPJ,1,8)

		If ::DataNasc == nil
			dDataNasc := SToD("        ")
		Else
			dDataNasc := ::DataNasc
		EndIf

		// Formatacao de codigo e loja.
		// A partir daqui nao pode mais usar AllTrim em nenhuma das 2 variaveis
		DBSelectArea("SA1")
		SA1->(DBSetOrder(1))
		While (.T.)
			cCodigo := GETSXENUM("SA1","A1_COD")
			If !SA1->(DBSeek(xFilial("SA1") + cCodigo))
			    U_ITConOut("[WS_ADD_CLIENTE] Sera incluido esse codigo: "+cCodigo)
				SA1->(rollbackSx8())
				Exit
			EndIf
			U_ITConOut("[WS_ADD_CLIENTE] Ja existe esse codigo: "+cCodigo)
			SA1->(ConfirmSX8())
		EndDo

	  	//cCodigo := GetNumSA1()
		If _lProspct
		   cLoja:= LEFT(RIGHT(AllTrim(cCnpj),6),4)
		Else   
		   cLoja:= "0001"
        EndIf
		// Campos fixos pelo padrão
		cPaisBacen	:= "01058"
		cPais		:= "105"

		// regra 01 - se o nome reduzido estiver em branco, assumo o campo cRazão, que alimentará o A1_NOME
		If Empty(AllTrim(cNomefantasia))
			cNomefantasia := cRazaosocial
		Else
			cNomefantasia := AllTrim(cNomefantasia)
		EndIf

		cCONTATO:=""
		cCARGC  :=""
		cEMAILC :=""
		If Type("tAdContato:zzItensDoContato") == "A"
		   nItem:=1
		   oSU5Tmp:=::tAdContato:zzItensDoContato
		   If Len(oSU5Tmp) > 0 
	          If Type("oSU5Tmp[nItem]:CONTATONOME"	)  = 'C'
	             cCONTATO:=AllTrim(Upper(oSU5Tmp[nItem]:CONTATONOME))
	          EndIf    
	          If Type("oSU5Tmp[nItem]:CONTATOFUNCAO" ) = 'C'
	             cCARGC  :=AllTrim(Upper(oSU5Tmp[nItem]:CONTATOFUNCAO))
	          EndIf	  
	          If Type("oSU5Tmp[nItem]:CONTATOEMAIL") == "C"
	             cEMAILC :=AllTrim(Upper(oSU5Tmp[nItem]:CONTATOEMAIL))
	          EndIf	  
            EndIf
		EndIf

		// Formatando a variável cCnae, em algumas integrações esta informação está vindo sem formatação.
		If ! Empty(cCnae) 
           cCnae := StrTran( cCnae , "." , "" )
		   cCnae := StrTran( cCnae , "/" , "" )
		   cCnae := StrTran( cCnae , "-" , "" )
           cCnae := SubStr(cCnae,1,4) + "-" + SubStr(cCnae,5,1) + "/" + SubStr(cCnae,6,2)
        EndIf 

		aAdd(aVetor,{"A1_COD"		,cCodigo		,Nil})
		aAdd(aVetor,{"A1_LOJA"		,cLoja			,Nil})
		aAdd(aVetor,{"A1_NOME"		,cRazaoSocial	,Nil})
		aAdd(aVetor,{"A1_NREDUZ"	,cNomeFantasia	,Nil})
		aAdd(aVetor,{"A1_PFISICA"	,cRgFisica		,Nil})
		aAdd(aVetor,{"A1_TIPO"		,cTipo			,Nil})
		aAdd(aVetor,{"A1_PESSOA"	,cFisicaJuridica,Nil})
		aAdd(aVetor,{"A1_CGC"		,cCnpj			,Nil})
		aAdd(aVetor,{"A1_EST"		,cEstado		,Nil})
		aAdd(aVetor,{"A1_COD_MUN"	,cCodMunicipio	,Nil})
		aAdd(aVetor,{"A1_INSCR"		,cInsEstadual	,Nil})
		aAdd(aVetor,{"A1_INSCRM"	,cInsMunicipal	,Nil})
		aAdd(aVetor,{"A1_INSCRUR"	,cInsRural		,Nil})
		aAdd(aVetor,{"A1_DTNASC"	,dDataNasc		,Nil})
		aAdd(aVetor,{"A1_HPAGE"		,cHomePage		,Nil})
		aAdd(aVetor,{"A1_TEL"		,cTelefone		,Nil})    
		aAdd(aVetor,{"A1_DDD"		,cDDD   		,Nil})    		
		aAdd(aVetor,{"A1_FAX"		,cTelFax		,Nil})
		aAdd(aVetor,{"A1_EMAIL"		,cEmail			,Nil})
		aAdd(aVetor,{"A1_CEP"		,cCEP			,Nil})
		aAdd(aVetor,{"A1_END"		,cEndereco		,Nil})
		aAdd(aVetor,{"A1_BAIRRO"	,cBairro		,Nil})
		aAdd(aVetor,{"A1_COMPLEM"	,cComplemento	,Nil})
		aAdd(aVetor,{"A1_OBS"		,cObservacao	,Nil})
		aAdd(aVetor,{"A1_VEND"		,cVendedor		,Nil})
		aAdd(aVetor,{"A1_DTCAD"		,dDataCadastro	,Nil})
		aAdd(aVetor,{"A1_HRCAD"		,cHoraCadastro	,Nil})
		aAdd(aVetor,{"A1_SUFRAMA"	,cSuframa		,Nil})
		aAdd(aVetor,{"A1_CNAE"		,cCNAE			,Nil})
		aAdd(aVetor,{"A1_CODPAIS"	,cPaisBacen		,Nil})
		aAdd(aVetor,{"A1_PAIS"		,cPais			,Nil})
		aAdd(aVetor,{"A1_MSBLQL"	,"2"			,Nil})
		aAdd(aVetor,{"A1_I_DW"		,cNumeroDw		,Nil})//A1_NUMDW
		aAdd(aVetor,{"A1_I_GRCLI"	,cSegmento		,Nil})
		aAdd(aVetor,{"A1_I_SUBCO"   ,cSubSegmen     ,Nil}) 
		aAdd(aVetor,{"A1_TRANSP"	,cTransportadora,Nil})
		aAdd(aVetor,{"A1_COND"	    ,cCond          ,Nil})
		aAdd(aVetor,{"A1_GRPVEN"	,cGrupoVenda    ,Nil})				
		aAdd(aVetor,{"A1_I_CCHEP"	,cCCHEP			,Nil})
		aAdd(aVetor,{"A1_I_CHEP"	,If(Empty(cCCHEP),"P","C"),Nil})
		//ConOut("****[WS_ADD_CLIENTE] ValType(nLC)    "+ValType(nLC)) 
		If ValType(nLC) = "N"
		   aAdd(aVetor,{"A1_I_SLC"	,nLC   			,Nil})				
		Else
		   aAdd(aVetor,{"A1_I_SLC"	,0   			,Nil})				
		EndIf
		aAdd(aVetor,{"A1_CONTATO"   ,cCONTATO		,Nil})
		aAdd(aVetor,{"A1_I_CARGC"   ,cCARGC		    ,Nil})
		aAdd(aVetor,{"A1_I_EMAIL"   ,cEMAILC		,Nil})
        If SA1->(FieldPos("A1_I_ORIGD")) > 0
		   aAdd(aVetor,{"A1_I_ORIGD","D"	   		,Nil})
		EndIf   

	    SA3->( DBSetOrder(1) )
	    If SA3->( DBSeek( xFilial('SA3') +cVendedor ) )
		   aAdd(aVetor,{"A1_TABELA"	,SA3->A3_I_TABPR ,Nil})				
		   aAdd(aVetor,{"A1_RISCO"	,SA3->A3_I_RISCO ,Nil})				
		   aAdd(aVetor,{"A1_LC"	    ,SA3->A3_I_LC	 ,Nil})				
		EndIf		   

		If _lProspct
           GravaProspct(aVetor,cCCHEP)
        Else
           //MSExecAuto( {|x,y,z| mata030(x,y,z) } , aVetor ,, 3 )  
		   MSExecAuto({|x,y| Mata030(x,y)},aVetor,nOpc) // nOpc = 3 - inclusão, 4 - Alteracao
		EndIf   

		If lMsErroAuto
			aAutoErro := GETAUTOGRLOG()
			_cObs := "[WS_ADD_CLIENTE] "+AllTrim(xDatAt() + "[ERRO] [WS_ADD_CLIENTE] " + XCONVERRLOG(aAutoErro))
			SetSoapFault("Retorno",LEFT(_cObs,60))
			U_ITConOut(_cObs)
			::AtualCliente := "[FALSO] Erro ao realizar a atualizacao do Cliente " + _cObs
			lRet := .F.
		Else
			// verifico se realmente o cliente foi adicionado no Protheus
			If _lProspct
				::AtualCliente := AllTrim(Str(SZX->(RECNO())))//"[SUCESSO] Cliente Gravado no Prospct Nr. DW: " + cNumeroDw
			Else
				SA1->(DBSetOrder(RetOrder("SA1","A1_FILIAL+A1_CGC")))
				If SA1->(DBSeek(xFilial("SA1")+PadR(cCNPJ,TamSX3("A1_CGC")[1])))
					::AtualCliente := SA1->A1_COD+SA1->A1_LOJA//"[SUCESSO] - Cliente gravado com o código: " + SA1->A1_COD + " - Loja: " + SA1->A1_LOJA // SA1->A1_COD+SA1->A1_LOJA
					U_ITConOut("[WS_ADD_CLIENTE] Cliente " + SA1->A1_COD +" - "+ SA1->A1_LOJA + " - " + IIf(nOpc == 4,"alterado","incluido") + " com sucesso!")
					
				Else
					_cMsgErro 	:= "CNPJ nao localizado apos inclusao do cliente: "
					_cMsgErro	+=  Transform(cCNPJ,IIf(Len(cCNPJ) < 14,"@R 999.999.999-99","@R! NN.NNN.NNN/NNNN-99"))
					_cObs 		:= "ERRO:" + _cMsgErro
					SetSoapFault("Retorno",LEFT(_cObs,60))
					U_ITConOut(_cObs)
					::AtualCliente := "[FALSO] Erro ao realizar a atualizacao do Cliente " + _cObs
					lRet := .F.
				EndIf
			EndIf
		EndIf
	EndIf
Else
	::AtualCliente := "[FALSO] Cliente ja cadastrado, codigo: " + SA1->A1_COD + " - " + SA1->A1_LOJA
EndIf

endtran()

U_ITConOut("[WS_ADD_CLIENTE] Fim: " + Time() + " Data: " + DToC(Date()))
U_ITConOut("[WS_ADD_CLIENTE] "+Repl("-",150))

Return lRet

//=========================================================================================================================
// função que cria / altera os contatos

Static Function WSADDCONTATO(xCodigo,xLoja,oSU5Tmp,cCONTATO)

Local nItem		:= 0
//Local xCodCont	:= ""
Local nItens 	:= 0
Local _aItCont	:= oSU5Tmp
//Local cxCARGC:=cxEMAILC:=""

nItens := Len(_aItCont)

U_ITConOut("[WS_ADD_CLIENTE] Lendo  " +AllTrim(Str(nItens))+ " contatos " )

For nItem := 1 to nItens
	If nItem == 1
	   If Type("oSU5Tmp[nItem]:CONTATONOME"	)  = 'C'
	      cCONTATO:=AllTrim(Upper(oSU5Tmp[nItem]:CONTATONOME))
	   EndIf

	   If Type("oSU5Tmp[nItem]:CONTATOFUNCAO" ) = 'C'
	      cCARGC  :=AllTrim(Upper(oSU5Tmp[nItem]:CONTATOFUNCAO))
	   EndIf	  
	   If Type("oSU5Tmp[nItem]:CONTATOEMAIL") == "C"
	      cEMAILC :=AllTrim(Upper(oSU5Tmp[nItem]:CONTATOEMAIL))
	   EndIf	  
    EndIf
Next nX

Return  

//==========================================================================================================================
// função que converte o log, deixando-o mais "apresentável"

Static Function xConverrLog(aAutoErro)

Local cRet := ""
Local _nI   := 1

For _nI := 1 to Len(aAutoErro)
	cRet += CRLF + AllTrim(aAutoErro[_nI])
Next _nI

Return cRet

//==========================================================================================================================
//função que retorna a data atual em formato CARACTERE

Static Function xDatAt()

Local cRet	:=	""

//cRet :=	CRLF + "(" + DToC(DATE()) + " " + Time() + ")"

Return(cRet)


//===========================================================================================================================
// função que remove a máscara do CNPJ

Static Function UnMaskCNPJ( cCNPJ )

Local cCNPJClear := cCNPJ

Begin Sequence

	If Empty( cCNPJClear )
		BREAK
	EndIf

	cCNPJClear := StrTran( cCNPJClear , "." , "" )
	cCNPJClear := StrTran( cCNPJClear , "/" , "" )
	cCNPJClear := StrTran( cCNPJClear , "-" , "" )
	cCNPJClear := AllTrim( cCNPJClear )

End Sequence

Return(cCNPJClear)

//===========================================================================================================================
// Função que valida a existencia do código DW no cliente

Static Function FChkIdDW(cIdDW,cTabela)

Local aArea		:=	FWGetArea()
Local cAliasTrb	:=	GetNextAlias()
Local aQuery	:=	{}
Local lRet		:=	.F.

Default cIdDW	:=	""
Default	cTabela	:=	""

//-----------------------------------------------------------------
// Consulta se o cliente DW já existe na base de dados do Protheus
//-----------------------------------------------------------------
If cTabela == "SA1" .And. SA1->(FieldPos("A1_I_DW")) > 0

	BeginSql Alias cAliasTrb

		SELECT
			SA1.A1_FILIAL,
			SA1.A1_COD,
			SA1.A1_LOJA,
			SA1.A1_NOME,
			SA1.A1_CGC,
			SA1.R_E_C_N_O_ AS SA1_RECNO
		FROM
			%Table:SA1% SA1 (NOLOCK)
		WHERE
			SA1.%NotDel%
			AND	SA1.A1_I_DW = %Exp:cIdDW%
		ORDER BY
			%Order:SA1%
	EndSql

	aQuery := GetLastQuery(cAliasTrb)

	If (cAliasTrb)->SA1_RECNO > 0
		lRet := .T.
	EndIf

ElseIf cTabela == "SZX" .And. SZX->(FieldPos("ZX_I_DW")) > 0

	BeginSql Alias cAliasTrb

		SELECT SZX.R_E_C_N_O_ AS SZX_RECNO
		FROM
			%Table:SZX% SZX (NOLOCK)
		WHERE
			SZX.%NotDel%
			AND	SZX.ZX_I_DW = %Exp:cIdDW%
		ORDER BY
			%Order:SZX%
	EndSql

	aQuery := GetLastQuery(cAliasTrb)

	If (cAliasTrb)->SZX_RECNO > 0
		lRet := .T.
	EndIf

EndIf

If Select(cAliasTrb) > 0
	DBSelectArea(cAliasTrb)
	DBCloseArea()
EndIf

FWRestArea(aArea)

Return(lRet)

/*
===============================================================================================================================
Programa--------: GravaProspct()
Autor-----------: Alex Wallauer
Data da Criacao-: 10/01/2019
Descrição-------: Inclui dados do cliente no Prospct
Parametros------: aVetor,cCCHEP
Retorno---------:(.T.)
===============================================================================================================================
*/
Static Function GravaProspct(aVetor,cCCHEP)

Local _aGrava:={},_nCpo,_nPos
//Local _cTeste:=""
Local _aCampos:={;
{ "A1_NOME"	  ,"ZX_NOME"  },;
{ "A1_PESSOA" ,"ZX_PESSOA"},;
{ "A1_CGC"	  ,"ZX_CGC"   },;
{ "A1_NREDUZ" ,"ZX_NREDUZ"},;
{ "A1_TIPO"	  ,"ZX_TIPO"  },;
{ "A1_EST"	  ,"ZX_EST"   },;
{ "A1_COD_MUN","ZX_CODMUN"},;
{ "A1_CEP"	  ,"ZX_CEP"},;
{ "A1_DDD"	  ,"ZX_DDD"},;
{ "A1_TEL"	  ,"ZX_TEL"},;
{ "A1_END"	  ,"ZX_END"},;
{ "A1_BAIRRO" ,"ZX_BAIRRO" },;//{ "A1_TELEX"  ,"ZX_TELEX"  },;
{ "A1_FAX"	  ,"ZX_FAX"    },;
{ "A1_PAIS"	  ,"ZX_PAIS"   },;
{ "A1_INSCR"  ,"ZX_INSCR"  },;
{ "A1_PFISICA","ZX_PFISICA"},;
{ "A1_DTNASC" ,"ZX_DTNASC" },;
{ "A1_EMAIL"  ,"ZX_EMAIL"  },;
{ "A1_HPAGE"  ,"ZX_HPAGE"  },;
{ "A1_INSCRM" ,"ZX_INSCRM" },;
{ "A1_INSCRUR","ZX_INSCRUR"},;
{ "A1_COMPLEM","ZX_COMPLEM"},;//{ "A1_CEPC"	  ,"ZX_CEP"    },;
{ "A1_VEND"	  ,"ZX_VEND"   },;
{ "A1_GRPVEN" ,"ZX_I_GRPVE"},;
{ "A1_COND"	  ,"ZX_CONDPAG"},;
{ "A1_I_GRCLI","ZX_GRCLI"  },;//{ "A1_RISCO"  ,"ZX_I_RISCO"},;//{ "A1_VENCLC" ,"ZX_I_VENCL"},;//{ "A1_CONTRIB","ZX_CONTRIB"},;
{ "A1_I_SUBCO","ZX_SUB_COD"},; 
{ "A1_CNAE"   ,"ZX_I_END"  },;
{ "A1_CONTATO","ZX_CONTATO"},;
{ "A1_I_CARGC","ZX_CARGC"  },;
{ "A1_I_EMAIL","ZX_EMAILC" },;//{ "A1_SIMPNAC","ZX_SIMPNAC"},; 
{ "A1_LOJA"	  ,"ZX_LOJA"   },;
{ "A1_I_CCHEP","ZX_I_CCHEP"} }

DBSelectArea("SZX")
aAdd(_aCampos,{ "A1_I_DW" ,"ZX_I_DW" } )
aAdd(_aCampos,{ "A1_I_SLC","ZX_I_SLC"} )


aAdd(_aGrava,{"ZX_FILIAL" ,xFilial("SZX")})
aAdd(_aGrava,{"ZX_EMISSAO",Date()        })
aAdd(_aGrava,{"ZX_CODEMP" ,'010'         })
aAdd(_aGrava,{"ZX_MSBLQL" ,'2'           })
aAdd(_aGrava,{"ZX_STATUS" ,'L'           })
aAdd(_aGrava,{"ZX_EVENTO" ,'0'           })
aAdd(_aGrava,{"ZX_TIMEEMI",FWTimeStamp( 4, DATE(), Time() ) })
aAdd(_aGrava,{"ZX_CHEP"   ,If(Empty(cCCHEP),"N","S")})

If SZX->(FieldPos("ZX_I_ORIGD")) > 0
   aAdd(_aGrava,{"ZX_I_ORIGD" ,'D'       })
EndIf 
                                
For _nCpo:= 1 TO Len(_aCampos)
   If (_nPos:=aScan(aVetor, {|I| I[1] == _aCampos[_nCpo,1] } )) > 0
                    //1-compo         2-conteudo
      aAdd(_aGrava,{_aCampos[_nCpo,2],aVetor[_nPos,2]}) 
   EndIf   
Next

BEGIN TRANSACTION

SZX->(RecLock("SZX",.T.))
For _nCpo := 1 To Len(_aGrava)
    If SZX->(FieldPos(_aGrava[_nCpo][1])) > 0
	   SZX->(FieldPut( FieldPos(_aGrava[_nCpo][1]) , _aGrava[_nCpo][2] ))
	EndIf   
Next
SZX->(MSUnLock())

END TRANSACTION

Return .T.
