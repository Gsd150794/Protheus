/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |15/07/2025| Chamado 48781. Ajustes para busca de titulo na SE2 e gravação do campo Serie do Documento.
Lucas Borges  |17/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "RESTFUL.Ch"
#Include "TBICONN.CH"

Static _nRecnoZ32 := 0
Static _nRecnoZ34 := 0
//*************
// POST
//*************
WsRestful AOMS148 Description "WebService REST Italac x TMS Multiembarcador"

   WsMethod Post Fatura Description "Gravar dados da Fatura do Embarcador na temporaria" PATH "/AOMS148/Fatura"  WsSyntax "/AOMS148/Fatura" 

End WsRestFul

WsMethod POST Fatura WsService AOMS148
   Local _cBody    As Character
   Local _cErro    As Character
   Local _aRecFat  As Array
   Local _aRecnos  As Array
   Local _lRetorno As Logical
   Local _nI       As Numeric
   Local _cNome    As Character
   Local _cResp    As Character 
   Local _cIDInte  As Character

   _cBody    := ::GetContent()
   _cErro    := ""
   _aRecFat  := {}
   _aRecnos  := {}
   _lRetorno := .F.
   _nI       := 0
   _cNome    := ""
   _cIDInte  := ""

   If DecodeUtf8(_cBody) <> Nil
      _cBody := DecodeUtf8(_cBody)
   EndIf

   _lRetorno := U_AOMS148(_cBody,@_cErro,.T.,@_aRecFat,@_cNome,@_cIDInte)
   
   If _lRetorno 
      _cResp := '{ "retorno":"200" , "mensagem":"Integrado com sucesso!", "IDIntegracaoProtheus":"'+_cIDInte+'" }'

      ::SetResponse(_cResp)

      If Empty(AllTrim(_cErro))
         _lRetorno := AOMS148Arq(_aRecFat,_cNome,@_cErro)
      Else
         _lRetorno := .F.
      EndIf

      Z34->(DBGoTo(_nRecnoZ34))
      Z34->(RecLock("Z34",.F.))
      Z34->Z34_STATUS := IIf(_lRetorno,"G","I")
      Z34->(MSUnLock())

      Z32->(DBGoTo(_nRecnoZ32))
      Z32->(RecLock("Z32",.F.))
      Z32->Z32_STATUS := IIf(_lRetorno,"G","I")
      Z32->Z32_RESPOS := _cResp
      Z32->Z32_ERRO   := _cErro
      Z32->(MSUnLock())

   Else
      _cResp := '{ "retorno":"500" , "mensagem":"Integracao nao realizada!", "ID de Integracao Protheus":"'+_cIDInte+'", "Erro":"'+_cErro+'" }'

      //SetRestFault(400,'Ops')
      ::setStatus(500) 
      ::SetResponse( _cResp )

      Z32->(DBGoTo(_nRecnoZ32))
      Z32->(RecLock("Z32",.F.))
      Z32->Z32_STATUS := "N"
      Z32->Z32_RESPOS := _cResp
      Z32->Z32_ERRO   := _cErro
      Z32->(MSUnLock())

   EndIf	

Return(.T.)

/*
===============================================================================================================================
Programa----------: AOMS148
Autor-------------: Igor Melgaço
Data da Criacao---: 03/04/2025
Descrição---------: Realiza de Integração - Chamado: 48781
Parametros--------: _cBody, _cErro, _lRest, _aRecFat, _cNome, _cIDInte
Retorno-----------: .T.  
===============================================================================================================================
*/ 
User Function AOMS148(_cBody As Character,_cErro As Character,_lRest As Logical,_aRecFat As Array,_cNome As Character, _cIDInte As Character) As Logical

Local _aDocs     As Array
Local _cNrfatura As Character
Local _cDtHrFatu As Character
Local _cTpOper   As Character
Local _cTpCarga  As Character
Local _cTomador  As Character
Local _cVrFatura As Character
Local _nVrDesc   As Numeric
Local _nVrAcresc As Numeric
Local _cObsFatur As Character
Local _cTCpfCnpj As Character
Local _cCodInteg As Character
Local _nI        As Numeric
Local _aAuxZ32   As Array
Local _aAuxZ33   As Array
Local _aAuxZ34   As Array
Local _lRet      As Logical
Local _cCod      As Character
Local _cLoja     As Character
Local _dData     As Date
Local _cHora     As Character

Default _cErro   := ""
Default _lRest   := .T.
Default _aRecFat := {}

Private oJsoAux     As Object
Private lMsErroAuto As Logical

_aDocs     := {}
_cNrfatura := ""
_cDtHrFatu := ""
_cTpOper   := ""
_cTpCarga  := ""
_cTomador  := ""
_cVrFatura := ""
_nVrDesc   := 0
_nVrAcresc := 0
_cObsFatur := ""
_cTCpfCnpj := ""
_cCodInteg := ""
_nI        := 0
_aAuxZ32   := {}
_aAuxZ33   := {}
_aAuxZ34   := {}
_lRet      := .T.
_cCod      := ""
_cLoja     := ""
_dData     := CTOD("")
_cHora     := ""

oJsoAux    := Nil
lMsErroAuto := .F.

FWJsonDeserialize(_cBody, @oJsoAux)

_cFilial := oJsoAux:FILIAL

If _lRest
   RpcClearEnv()
   RpcSetEnv("01",_cFilial)
EndIf
   
_cNrfatura := IIf(AttIsMemberOf(oJsoAux,"nrofatura")    ,AllTrim(Str(oJsoAux:nrofatura)),"") 
_cDtHrFatu := IIf(AttIsMemberOf(oJsoAux,"dataHoraFatura")    ,oJsoAux:dataHoraFatura,"") 
_cTpOper   := IIf(AttIsMemberOf(oJsoAux,"tipoOperacao")    ,oJsoAux:tipoOperacao,"") 
_cTpCarga  := IIf(AttIsMemberOf(oJsoAux,"tipoCarga")    ,oJsoAux:tipoCarga,"") 
_cTomador  := IIf(AttIsMemberOf(oJsoAux,"tomador")    ,oJsoAux:tomador,"") 
_cVrFatura := IIf(AttIsMemberOf(oJsoAux,"valorFatura")    ,oJsoAux:valorFatura,"") 
_nVrDesc   := IIf(AttIsMemberOf(oJsoAux,"valorDesconto")    ,oJsoAux:valorDesconto,"") 
_nVrAcresc := IIf(AttIsMemberOf(oJsoAux,"valorAcrescimo")    ,oJsoAux:valorAcrescimo,"") 
_cObsFatur := IIf(AttIsMemberOf(oJsoAux,"obsFatura")    ,oJsoAux:obsFatura,"")  
_cTCpfCnpj := IIf(AttIsMemberOf(oJsoAux:transportador,"cpfCnpj")    ,oJsoAux:transportador:cpfCnpj,"")  
_cCodInteg := IIf(AttIsMemberOf(oJsoAux:transportador,"codIntegracao")    ,oJsoAux:transportador:codIntegracao,"") 

_lRet := AOMS148VT(_cTCpfCnpj,@_cCod,@_cLoja,@_cNome,@_cErro)

If AttIsMemberOf(oJsoAux,"documentos") 
   For _nI := 1 To Len(oJsoAux:documentos)
      
      If _lRet
         _cNrDoc    := U_ITKEY(oJsoAux:documentos[_nI]:numeroDocumento,"F1_DOC")  
         _cTipoDoc  := U_ITKEY(oJsoAux:documentos[_nI]:tipoDocumento,"F1_TIPO")  
         _cSerieDoc := U_ITKEY(oJsoAux:documentos[_nI]:serieDocumento,"F1_SERIE")  

         _lRet := AOMS148VF(_cCod,_cLoja,_cNome,_cSerieDoc,_cNrDoc,oJsoAux:documentos[_nI]:valorTotalDocumento,@_cErro,@_aRecFat)				
      EndIf

      aAdd(_aDocs,{;
            IIf(AttIsMemberOf(oJsoAux:documentos[_nI],"numeroDocumento")    ,AllTrim(Str(oJsoAux:documentos[_nI]:numeroDocumento)),""),;
            IIf(AttIsMemberOf(oJsoAux:documentos[_nI],"tipoDocumento")      ,oJsoAux:documentos[_nI]:tipoDocumento,""),;
            IIf(AttIsMemberOf(oJsoAux:documentos[_nI],"serieDocumento")      ,oJsoAux:documentos[_nI]:serieDocumento,""),;
            IIf(AttIsMemberOf(oJsoAux:documentos[_nI],"numeroNFe")          ,oJsoAux:documentos[_nI]:numeroNFe,""),;
            IIf(AttIsMemberOf(oJsoAux:documentos[_nI],"serieNfe")           ,oJsoAux:documentos[_nI]:serieNfe,""),;  
            IIf(AttIsMemberOf(oJsoAux:documentos[_nI],"valorTotalDocumento"),oJsoAux:documentos[_nI]:valorTotalDocumento,0),;
            IIf(AttIsMemberOf(oJsoAux:documentos[_nI],"numeroCarga")        ,oJsoAux:documentos[_nI]:numeroCarga,""),;
            IIf(AttIsMemberOf(oJsoAux:documentos[_nI],"protocoloCarga")     ,AllTrim(Str(oJsoAux:documentos[_nI]:protocoloCarga)),""),;
            IIf(AttIsMemberOf(oJsoAux:documentos[_nI],"protocoloPedido")    ,AllTrim(Str(oJsoAux:documentos[_nI]:protocoloPedido)),""),;
            IIf(AttIsMemberOf(oJsoAux:documentos[_nI],"chaveCTE")           ,oJsoAux:documentos[_nI]:chaveCTE,"");
            })

   Next
Else
   _lRet := .F.
   _cErro := "Não foi informado os documentos da fatura."
EndIf

_cIDinte := AOMS148GNU()
_dData   := Date()
_cHora   := Time()

aAdd(_aAuxZ34, {"Z34_FILIAL", _cFilial				, Nil})
aAdd(_aAuxZ34, {"Z34_NRFAT" , _cNrfatura			, Nil})
aAdd(_aAuxZ34, {"Z34_CODINT", _cCodInteg			, Nil})
aAdd(_aAuxZ34, {"Z34_DATA"  , _dData				, Nil})
aAdd(_aAuxZ34, {"Z34_HORA"	 , _cHora				, Nil})
aAdd(_aAuxZ34, {"Z34_IDINTE", _cIDinte				, Nil})
aAdd(_aAuxZ34, {"Z34_CNPJTR", _cTCpfCnpj			, Nil})
aAdd(_aAuxZ34, {"Z34_TOMADO", _cTomador         , Nil})
aAdd(_aAuxZ34, {"Z34_VRFAT" , _cVrFatura			, Nil})
aAdd(_aAuxZ34, {"Z34_VRDESC", _nVrDesc				, Nil})
aAdd(_aAuxZ34, {"Z34_VRACRE", _nVrAcresc			, Nil})
aAdd(_aAuxZ34, {"Z34_OBS"   , _cObsFatur			, Nil})	
aAdd(_aAuxZ34, {"Z34_STATUS", IIf(_lRet,"I","N"), Nil})
aAdd(_aAuxZ34, {"Z34_ERRO"  , _cErro				, Nil})      
aAdd(_aAuxZ34, {"Z34_COD"   , _cCod					, Nil})
aAdd(_aAuxZ34, {"Z34_LOJA"  , _cLoja				, Nil})
aAdd(_aAuxZ34, {"Z34_NOME"  , _cNome				, Nil})

AOMS148Z34(_aAuxZ34,_cErro,.T.)

//Monta array de Dados da tabela Z32
aAdd(_aAuxZ32, {"Z32_FILIAL", _cFilial       , Nil})
aAdd(_aAuxZ32, {"Z32_NRFAT" , _cNrfatura     , Nil})
aAdd(_aAuxZ32, {"Z32_IDINTE", _cIDinte       , Nil})
aAdd(_aAuxZ32, {"Z32_DATA"  , _dData         , Nil})
aAdd(_aAuxZ32, {"Z32_HORA" , _cHora          , Nil})
aAdd(_aAuxZ32, {"Z32_TIPOOP", _cTpOper			, Nil})
aAdd(_aAuxZ32, {"Z32_TIPOCA", _cTpCarga      , Nil})
aAdd(_aAuxZ32, {"Z32_TOMADO", _cTomador      , Nil})
aAdd(_aAuxZ32, {"Z32_VRFAT" , _cVrFatura     , Nil})
aAdd(_aAuxZ32, {"Z32_VRDESC", _nVrDesc       , Nil})
aAdd(_aAuxZ32, {"Z32_VRACRE", _nVrAcresc     , Nil})
aAdd(_aAuxZ32, {"Z32_OBS"   , _cObsFatur     , Nil})	
aAdd(_aAuxZ32, {"Z32_CNPJTR", _cTCpfCnpj     , Nil})
aAdd(_aAuxZ32, {"Z32_CODINT", _cCodInteg     , Nil})
aAdd(_aAuxZ32, {"Z32_PAYLOA", _cBody         , Nil})
aAdd(_aAuxZ32, {"Z32_DTHR"	, _cDtHrFatu		      , Nil})
aAdd(_aAuxZ32, {"Z32_STATUS", IIf(_lRet,"I","N")   , Nil})
aAdd(_aAuxZ32, {"Z32_ERRO"  , _cErro				   , Nil})      
aAdd(_aAuxZ32, {"Z32_COD"   , _cCod				      , Nil})
aAdd(_aAuxZ32, {"Z32_LOJA"  , _cLoja			      , Nil})
aAdd(_aAuxZ32, {"Z32_NOME"  , _cNome			      , Nil})

AOMS148GRV("Z32",_aAuxZ32,.T.,@_nRecnoZ32)

For _nI := 1 To Len(_aDocs)
   _aAuxZ33 := {}
   aAdd(_aAuxZ33, {"Z33_FILIAL"  , _cFilial				, Nil})
   aAdd(_aAuxZ33, {"Z33_NRFAT"   , _cNrfatura			, Nil})
   aAdd(_aAuxZ33, {"Z33_IDINTE"  , _cIDinte				, Nil})
   aAdd(_aAuxZ33, {"Z33_NRDOC"   , _aDocs[_nI,1]  		, Nil})
   aAdd(_aAuxZ33, {"Z33_TPDOC"   , _aDocs[_nI,2]  		, Nil})
   aAdd(_aAuxZ33, {"Z33_SERDOC"  , _aDocs[_nI,3]  		, Nil})
   aAdd(_aAuxZ33, {"Z33_NRNFE"   , _aDocs[_nI,4]      , Nil})
   aAdd(_aAuxZ33, {"Z33_SERIE"   , _aDocs[_nI,5]      , Nil})
   aAdd(_aAuxZ33, {"Z33_VRTOT"   , _aDocs[_nI,6]      , Nil})
   aAdd(_aAuxZ33, {"Z33_NRCARGA"	, _aDocs[_nI,7]      , Nil})
   aAdd(_aAuxZ33, {"Z33_PROTCAR"	, _aDocs[_nI,8]      , Nil})
   aAdd(_aAuxZ33, {"Z33_PROTPED"	, _aDocs[_nI,9]      , Nil})
   aAdd(_aAuxZ33, {"Z33_CHVCTE"	, _aDocs[_nI,10]		, Nil})
   aAdd(_aAuxZ33, {"Z33_CODINT"	, _cCodInteg			, Nil})

   AOMS148GRV("Z33",_aAuxZ33,.T.)
Next

Return(.T.)

/*
===============================================================================================================================
Programa----------: AOMS148GRV
Autor-------------: Igor Melgaço
Data da Criacao---: 03/04/2025
Descrição---------: Grava tabelas Muro
Parametros--------: _cTabela, _aCampos, _lInclui, _nRecno
Retorno-----------: _lRet   
===============================================================================================================================
*/
Static Function AOMS148GRV(_cTabela As Character,_aCampos as Array,_lInclui as Logical,_nRecno As Numeric) As Logical

Local _lRet As Logical
Local _cErro As Character
Local _nI As Numeric

Default _nRecno := 0

_lRet  := .T.
_cErro := ""
_nI    := 0

Begin Transaction

   If (_cTabela)->(RecLock(_cTabela,_lInclui))
      For _nI := 1 To Len(_aCampos)
         (_cTabela)->&(_aCampos[_nI,1]) := _aCampos[_nI,2]
      Next
      (_cTabela)->(MSUnLock())

      _nRecno := (_cTabela)->(Recno())

        _lRet := .T.
   Else
      _lRet := .F.
      _cErro += "AOSM148GRV: [ "+MostraErro(Upper(GetSrvProfString("STARTPATH","")),"AOMS148.LOG")+" ]"
      DisarmTransaction()
   EndIf

End Transaction

Return(_lRet)

/*
===============================================================================================================================
Programa----------: AOMS148GNU
Autor-------------: Igor Melgaço
Data da Criacao---: 03/04/2025
Descrição---------: Retorna proximo numero de integração
Parametros--------: 
Retorno-----------: _cRetorno   
===============================================================================================================================
*/
Static Function AOMS148GNU() as Character

Local _cRetorno As Character
Local _cQuery As Character
Local _nTam As Numeric
Local _cAliasZ32 As Character

_cRetorno := ""
_cQuery   := ""
_nTam     := Len(Z32->Z32_IDINTE)
_cAliasZ32 := GetNextAlias()

//Resgata ID de integração
_cQuery := " SELECT MAX(Z32_IDINTE) AS ID "
_cQuery += " FROM " + RetSqlName("Z32")
_cQuery += " WHERE D_E_L_E_T_ <> '*'"

MPSysOpenQuery( _cQuery , _cAliasZ32)

DBSelectArea(_cAliasZ32)
DBGoTop()

_cRetorno := StrZero(Val(Right(AllTrim((_cAliasZ32)->ID),_nTam))+1,_nTam)

While !MayIUseCode( "Z32_IDINTE"+xFilial("Z32")+_cRetorno)  //verifica se esta na memoria, sendo usado
   _cRetorno := Soma1(_cRetorno)						 // busca o proximo numero disponivel
EndDo

DBSelectArea(_cAliasZ32)
DBCloseArea()

Return _cRetorno


/*
===============================================================================================================================
Programa----------: AOMS148VT
Autor-------------: Igor Melgaço
Data da Criacao---: 03/04/2025
Descrição---------: Valida Transportadora
Parametros--------: _cCnpj, _cCod, _cLoja, _cNome, _cErro
Retorno-----------: _lRet   
===============================================================================================================================
*/
Static Function AOMS148VT(_cCnpj As Character,_cCod As Character,_cLoja As Character,_cNome As Character,_cErro As Character) As Logical

Local _lRet As Logical
Local _cNewCnpj As Character
Local _nI As Numeric

_lRet := .F.
_cCnpj := AllTrim(_cCnpj)
_cNewCnpj := ""
_nI = 0

For _nI := 1 To Len(_cCnpj)
   If SubStr(_cCnpj,_nI,1) $ "0123456789"
      _cNewCnpj += SubStr(_cCnpj,_nI,1)
   EndIf
Next

DBSelectArea("SA2")
DBSetOrder(3)
If DBSeek(xFilial("SA2")+_cNewCnpj)
   _cCod  := SA2->A2_COD
   _cLoja := SA2->A2_LOJA
   _cNome := SA2->A2_NREDUZ

   If SA2->A2_MSBLQL
      _lRet := .F.
      _cErro := "Transportadora bloqueada!"
   Else
      _lRet := .T.
   EndIf
Else
   _lRet := .F.
   _cErro := "Transportadora não encontrada!"
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS148VF
Autor-------------: Igor Melgaço
Data da Criacao---: 03/04/2025
Descrição---------: Verifica o Saldo dos titulos
Parametros--------: _cCod, _cLoja, _cNome, _cSerie, _cNumero, _nValor, _cErro, _aRecnos
Retorno-----------: _lRet   
===============================================================================================================================
*/
Static Function AOMS148VF(_cCod As Character,_cLoja As Character,_cNome As Character,_cSerie As Character,_cNumero As Character,_nValor As Numeric,_cErro As Character,_aRecnos As Array) As Logical

Local _lRet    As Logical
Local _nSaldo  As Numeric

_lRet    := .F.
_nSaldo  := 0

_cCnpj := AllTrim(_cCnpj)
_cSerie := U_ITKEY(_cSerie,"E2_PREFIXO")
_cNumero := U_ITKEY(_cNumero,"E2_NUM")
_cNumero := StrZero(Val(_cNumero),Len(_cNumero))

SA2->(DBSetOrder(1))
ZZN->(DBSetOrder(9))

DBSelectArea("SE2")
DBSetOrder(6)
If DBSeek(xFilial("SE2")+_cCod+_cLoja+_cSerie+_cNumero)
   While xFilial("SE2")+_cCod+_cLoja+_cSerie+_cNumero == SE2->(E2_FILIAL + E2_FORNECE + E2_LOJA + E2_PREFIXO + E2_NUM) .And. SE2->(!Eof())
      _nSaldo += SE2->E2_SALDO
      aAdd(_aRecnos,SE2->(Recno()))
      SE2->(DBSkip())
   EndDo

   If _nSaldo =  _nValor
      _lRet := .T.
   Else
      _lRet := .F.
      _cErro := " O saldo dos titulos diferem do valor do documento "+_cNumero+" para geração da fatura."
   EndIf
Else
   _lRet := .F.
   _cErro := " Não encontrado titulos do Documento "+_cNumero+" para geração da fatura."
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS148SE()
Autor-------------: Igor Melgaço
Data da Criacao---: 03/04/2025
Descrição---------: Gravação da tabela Z34
Parametros--------: _aAuxZ34, _cErro, _lBeginTra
Retorno-----------: _lContinua
===============================================================================================================================
*/
Static Function AOMS148Z34(_aAuxZ34 As Array,_cErro As Character,_lBeginTra As Logical) As Logical

Local _nI  As Numeric
Local _nPos As Numeric
Local _cNrFat As Character
Local _lContinua As Logical
Local _lInclui As Logical

_nI        := 0
_nPos      := 0
_cNrFat   := ""
_lContinua := .F.
_lInclui   := .F. 

If !(Len(_aAuxZ34) > 0)
   Return .F.
EndIf

If (_nPos := aScan(_aAuxZ34,{|A|A[1]=="Z34_NRFAT"})) <> 0
   _cNrFat := _aAuxZ34[_nPos,2]
Else
   Return .F.
EndIf

DBSelectArea("Z34")
DBSetOrder(1)
If DBSeek(xFilial("Z34")+_cNrFat)
   If Z34->Z34_STATUS == "G" 
      _lContinua := .F.
      _cErro += " Registro ja incluido anteriormente"
   Else
      _lContinua := .T.
   EndIf
   _lInclui := .F.
Else
   _lContinua := .T.
   _lInclui := .T.
EndIf

If _lContinua
   If _lBeginTra
      Begin Transaction
         Z34->(RecLock("Z34",_lInclui))
         For _nI := 1 To Len(_aAuxZ34)
            Z34->&(_aAuxZ34[_nI,1]) := _aAuxZ34[_nI,2]
         Next
         Z34->(MSUnLock())

         _nRecnoZ34 := Z34->(Recno())
      End Transaction
   Else
      Z34->(RecLock("Z34",_lInclui))
      For _nI := 1 To Len(_aAuxZ34)
         Z34->&(_aAuxZ34[_nI,1]) := _aAuxZ34[_nI,2]
      Next
      Z34->(MSUnLock())
   EndIf
   _nRecnoZ34 := Z34->(Recno())
EndIf

Return _lContinua

/*
===============================================================================================================================
Programa----------: AOMS148Arq
Autor-------------: Igor Melgaço
Data da Criacao---: 03/04/2025
Descrição---------: Rotina para criação do arquivo temporário
Parametros--------: _aRecnos, _cNome, _cErro
Retorno-----------: _lRet
===============================================================================================================================
*/
Static Function AOMS148Arq(_aRecnos As Array,_cNome As Character,_cErro As Character) As Logical

Local nUsado   As Numeric
Local _lTemReg As Logical
Local aEstru   As Array
Local _aSE2    As Array
Local nQtdTit  As Numeric
Local nValTit  As Numeric
Local _nI      As Numeric
Local _oTRBF   As Object

nUsado   := 0
_lTemReg :=.F.
aEstru   := {}
_aSE2    := {}
nQtdTit  := 0
nValTit  := 0
_nI      := 0
_oTRBF   := Nil

aAdd(_aSE2,"E2_PREFIXO")
aAdd(_aSE2,"E2_NUM"    )
aAdd(_aSE2,"E2_PARCELA")
aAdd(_aSE2,"E2_TIPO"   )
aAdd(_aSE2,"E2_NATUREZ")
aAdd(_aSE2,"E2_FORNECE")
aAdd(_aSE2,"E2_LOJA"   )
aAdd(_aSE2,"E2_EMISSAO")
aAdd(_aSE2,"E2_VENCREA")
aAdd(_aSE2,"E2_VALOR"  )
aAdd(_aSE2,"E2_SALDO"  )
aAdd(_aSE2,"E2_BAIXA"  )
aAdd(_aSE2,"E2_HIST"   )
aAdd(_aSE2,"E2_DATALIB")
aAdd(_aSE2,"E2_USUALIB")
aAdd(_aSE2,"E2_SDDECRE")
aAdd(_aSE2,"A2_NOME")

For nUsado := 1 To Len(_aSE2)
   aAdd( aEstru , {  Getsx3cache(_aSE2[nUsado],"X3_CAMPO")  ,;
                     Getsx3cache(_aSE2[nUsado],"X3_TIPO")   ,;
                     Getsx3cache(_aSE2[nUsado],"X3_TAMANHO"),;
                     Getsx3cache(_aSE2[nUsado],"X3_DECIMAL")})
Next

aAdd(aEstru,{"REC_SE2","N",10,0})
aAdd(aEstru,{"OK"     ,"C",02,0})
aAdd(aEstru,{"VLR_FAT","N",15,5})
aAdd(aEstru,{"TIPO"   ,"C",01,0})
aAdd(aEstru,{"PODALT" ,"L",01,0})
aAdd(aEstru,{"PODEST" ,"L",01,0})

//================================================================================
// Verifica se ja existe um arquivo com mesmo nome, se sim deleta.
//================================================================================
If Select("TRBF") > 0
   TRBF->(DBCloseArea())
EndIf

If ValType(_oTRBF) == "O"
   _oTRBF:Delete()
EndIf

_oTRBF := FWTemporaryTable():New( "TRBF", aEstru )
_oTRBF:AddIndex( "TR", {"E2_NUM"       } )
_oTRBF:AddIndex( "CO", {"TIPO","E2_NUM"} )
_oTRBF:AddIndex( "DT", {"E2_EMISSAO","E2_NUM"} )
_oTRBF:Create()

DBSelectArea("SE2")
For _nI := 1 To Len(_aRecnos)
   SE2->(DBGoTo(_aRecnos[_nI]))

   _cOK := "X"

   TRBF->(DBAPPEND())
   AVREPLACE("SE2","TRBF")

   TRBF->A2_NOME := _cNome
   TRBF->REC_SE2 := SE2->(Recno())
   TRBF->VLR_FAT := SE2->E2_SALDO - SE2->E2_SDDECRE
   TRBF->PODALT  := (SE2->E2_DECRESC = 0)
   TRBF->PODEST  := IIf(SE2->E2_SALDO == SE2->E2_VALOR ,.T.,.F.)
   
   If SE2->E2_TIPO = "NDF"
      TRBF->TIPO     := "9" //Nota de debito //AZUL
      TRBF->E2_SALDO := SE2->E2_SALDO*(-1)
      TRBF->E2_VALOR := SE2->E2_VALOR*(-1)
      TRBF->VLR_FAT  := TRBF->VLR_FAT*(-1)
      _cOK           := _cMarca
   ElseIf ZZN->(DBSeek(cFilant+SE2->E2_NUM+SE2->E2_PREFIXO+SE2->E2_FORNECE+SE2->E2_LOJA))
      TRBF->TIPO := "1" //Com canhoto com zzn //VERDE
      _cOK       := _cMarca
   Else
      TRBF->TIPO := "5" //Sem canhoto //AMARELO
   EndIf

   TRBF->OK := _cOK

   If !Empty(_cOK)
      nQtdTit++
      nValTit += TRBF->VLR_FAT
   EndIf

   _lTemReg:=.T.

Next

ZZN->(DBSetOrder(1))

_aTRBF := {}

TRBF->(DBSetOrder(2))
TRBF->(DBGoTop())
While TRBF->(!Eof())
   _aItens := {}
   
   aAdd(_aItens,TRBF->OK        )//01
   aAdd(_aItens,TRBF->E2_PREFIXO)//02
   aAdd(_aItens,TRBF->E2_NUM    )//03
   aAdd(_aItens,TRBF->E2_PARCELA)//04
   aAdd(_aItens,TRBF->E2_TIPO   )//05
   aAdd(_aItens,TRBF->E2_NATUREZ)//06
   aAdd(_aItens,TRBF->E2_LOJA   )//07
   aAdd(_aItens,TRBF->E2_EMISSAO)//08
   aAdd(_aItens,TRBF->E2_VENCREA)//09
   aAdd(_aItens,TRBF->E2_VALOR  )//10
   aAdd(_aItens,TRBF->E2_SALDO  )//11
   aAdd(_aItens,TRBF->E2_BAIXA  )//12
   aAdd(_aItens,TRBF->E2_HIST   );_nPosHistoric:=Len(_aItens)//13   _nPosHistoric se mudar atera essa variavel
   aAdd(_aItens,TRBF->E2_DATALIB)//14
   aAdd(_aItens,TRBF->E2_USUALIB)//15
   aAdd(_aItens,TRBF->E2_SDDECRE);_nPosDesconto:=Len(_aItens)//16 	_nPosDesconto se mudar atera essa variavel
   aAdd(_aItens,TRBF->VLR_FAT   )//17
   aAdd(_aItens,TRBF->E2_FORNECE)//18
   aAdd(_aItens,TRBF->TIPO      )//19
   aAdd(_aItens,TRBF->A2_NOME   )//20
   aAdd(_aItens,TRBF->(RECNO()) )//21 - ULITMO SEMPRE

   aAdd(_aTRBF,_aItens)

   TRBF->( DBSkip() )
EndDo
TRBF->(DBGoTop())

_lRet := AOMS148GE(.T.,@_cErro)

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS148GE()
Autor-------------: Igor Melgaço
Data da Criacao---: 03/04/2025
Descrição---------: Le Titulos marcados para gera os Faturas
Parametros--------: _lGera, _cErro
Retorno-----------: _lRetorno
===============================================================================================================================
*/
Static Function AOMS148GE(_lGera As Logical,_cErro As Character) As Logical

Local T           As Numeric
Local _aCab       As Array
Local _aSize      As Array
Local _lRet       As Logical
Local _cNrTitulos As Character
Local _lEMail     As Logical
Local _lRetorno   As Logical

Private _aTLinhas := {}

T           := 0
_aCab       := {}
_aSize      := {}
_lRet       := .T.
_cNrTitulos := ""
_lEMail     := .F.
_lRetorno   := .T.

_aTLinhas := {}

_nConta := 0

TRBF->(DBGoTop())
While TRBF->(!Eof())
   If _lEMail
      If !Empty(TRBF->OK)
         _nConta++
      EndIf
   ElseIf _lGera .And. !Empty(TRBF->OK)//GERACAO
      _nConta++
   ElseIf !_lGera .And. !Empty(TRBF->OK)//ESTORNO
      _nConta++
   EndIf

   If ! Empty(TRBF->OK) .And. ! TRBF->PODEST .And. !_lGera // Titulos que não podem ser estornados.
      _cNrTitulos += If(Empty(_cNrTitulos),"",", ") + AllTrim(TRBF->E2_NUM) + If(!Empty(TRBF->E2_PARCELA),"-","") + AllTrim(TRBF->E2_PARCELA)
   EndIf

   TRBF->(DBSkip())
EndDo

If _nConta = 0
   
   If _lEMail
      U_ITMsg("Nenhum Fatura Selecionada","Atenção",,1)
   Else
      U_ITMsg("Nenhum Titulo Selecionado","Atenção",,1)
   EndIf

   Return .F.

EndIf

If ! Empty(_cNrTitulos)
   U_ITMsg("Os títulos: " + _cNrTitulos + ", não podem ser estornados pois estão compensados parcialmente ou totalmente. ","Atenção",,1)
   Return .F.
EndIf

_cTot   := AllTrim(Str(_nConta))
_nTam   := Len(_cTot) + 1
_nConta := 0

SE2->( DBSetOrder(1) ) //E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA

aTitulos:={}
aTitAlt :={}

If _lEMail //REENVIO DE E-MAIL
   TRBF->(DBSetOrder(3))
EndIf

SA2->( DBSetOrder(1) )

TRBF->(DBGoTop())
SE2->(DBGoTo(TRBF->REC_SE2))

Private _dDtIni :=""//SE2->E2_EMISSAO//PRIMEIRO DA LISTA
Private _dDtFim :=""//SE2->E2_EMISSAO//PRIMEIRO DA LISTA

_aChaveFAT := {}

While TRBF->(!Eof())

   SE2->(DBGoTo(TRBF->REC_SE2))
   If _lEMail //REENVIO DE E-MAIL

      If !Empty(TRBF->OK)
         _nConta++

         AOMS148Tit(oProc,TRBF->REC_SE2,.T.)//CARREGA OS TITULOS DA FATURA NO _aTLinhas
         
         _aItens := {}//REENVIO _lEmail TIRULOS + FATURA

         aAdd(_aItens,.T.              )//01
         aAdd(_aItens,TRBF->E2_PREFIXO )//02
         aAdd(_aItens,TRBF->E2_NUM     )//03
         aAdd(_aItens,TRBF->E2_PARCELA )//04
         aAdd(_aItens,TRBF->E2_TIPO    )//05
         aAdd(_aItens,TRBF->E2_NATUREZ )//06
         aAdd(_aItens,TRBF->E2_FORNECE )//07
         aAdd(_aItens,TRBF->E2_LOJA    )//08
         aAdd(_aItens,DToC(TRBF->E2_EMISSAO))//09
         aAdd(_aItens,DToC(TRBF->E2_VENCREA))//10
         aAdd(_aItens,AllTrim(TRANSFORM((TRBF->E2_SALDO-TRBF->E2_SDDECRE)*If(TRBF->E2_TIPO="NDF",-1,1),"@E 999,999,999,999.99")))//11 // tira o desocnto para ficar = ao envio
         aAdd(_aItens,AllTrim(TRANSFORM(TRBF->E2_SDDECRE,"@E 999,999,999,999.99")))//12
         aAdd(_aItens,TRBF->E2_HIST)         //13
         aAdd(_aItens,"Gerado com sucesso")  //14
         aAdd(_aItens,(TRBF->E2_SALDO-TRBF->E2_SDDECRE)*If(TRBF->E2_TIPO="NDF",-1,1))//15
         aAdd(_aItens,TRBF->E2_SDDECRE)//16
         aAdd(_aTLinhas,_aItens)
         aAdd(_aChaveFAT, TRBF->REC_SE2 )//RENNO DA FATURA NO SE2 P/ O ANEXO

      EndIf

   ElseIf _lGera .And. !Empty(TRBF->OK)//GERACAO
      _nConta++

      If Empty(_dDtIni) .Or. SE2->E2_EMISSAO < _dDtIni
         _dDtIni := SE2->E2_EMISSAO
      EndIf

      If Empty(_dDtFim) .Or. SE2->E2_EMISSAO > _dDtFim
         _dDtFim := SE2->E2_EMISSAO
      EndIf

      // Considerar Loja do Fornededor 08/04/2021  aAdd(aTitulos,{SE2->E2_PREFIXO, SE2->E2_NUM, SE2->E2_PARCELA , SE2->E2_TIPO,.F.})//,SE2->E2_FORNECE,SE2->E2_LOJA
      aAdd(aTitulos,{SE2->E2_PREFIXO, SE2->E2_NUM, SE2->E2_PARCELA , SE2->E2_TIPO,.F.,SE2->E2_FORNECE,SE2->E2_LOJA	  })

      If aScan(aTitAlt,{|A|A[5]==TRBF->E2_FORNECE}) = 0 .And. SA2->(DBSeek(xFilial("SA2")+TRBF->E2_FORNECE))
         If Empty(SA2->A2_BANCO) .Or. Empty(SA2->A2_AGENCIA) .Or. Empty(SA2->A2_NUMCON)
            U_ITMsg("Banco ou agencia ou conta do cadastro do fornecedor não preenchido","Atenção",;
               "Cadastre para o fornecedor+loja: "+TRBF->E2_FORNECE+" "+SA2->A2_LOJA+" - "+SA2->A2_NREDUZ,1)
            Return .F.
         EndIf
      EndIf

      aAdd(aTitAlt ,{TRBF->REC_SE2   ,;//1
                     TRBF->E2_SDDECRE,;//2
                     (TRBF->E2_SDDECRE <> SE2->E2_SDDECRE .Or. TRBF->E2_HIST <> SE2->E2_HIST ),;//3
                     TRBF->E2_HIST   ,;//4
                     TRBF->E2_FORNECE})//5


   ElseIf !_lGera .And. !Empty(TRBF->OK) //ESTORNO
      _nConta++

      AOM115Estorno(oProc)//ESTORNO DA FATURA
   EndIf

   TRBF->(DBSkip())

EndDo

TRBF->(DBGoTop())

_cTot   := AllTrim(Str(Len(aTitAlt)))
_nTam   := Len(_cTot)+1
_nConta := 0

_lAlterouTodas := .T.

If _lGera .And. Len(aTitulos) > 0
   For T:= 1 To Len(aTitAlt)
      SE2->(DBGoTo( aTitAlt[T,1] ))
      _nConta++

      If aTitAlt[T,3] .And. !AOM114Altera(oProc,aTitAlt[T])//ALTERA E APROVEITA LIBERA OS TITULOS COM ALTERACAO DO DESCONTO E HISTORICO
         _lRet:=_lAlterouTodas:=.F.
         Exit
      EndIf
   Next

   If _lAlterouTodas
   
      _nConta := 0
   
      For T:= 1 To Len(aTitAlt)
         _nConta++

         If !aTitAlt[T,3] //SÓ LIBERA OS SEM ALTERACAO DO DESCONTO
            SE2->(DBGoTo( aTitAlt[T,1] ))
            SE2->(RecLock("SE2",.F.))
            SE2->E2_DATALIB := dDataBase
            SE2->E2_USUALIB := cUserName
            SE2->(MSUnLock())

            _aItens := {} //_lEmail TITULOS
            aAdd(_aItens,.T.)
            aAdd(_aItens,SE2->E2_PREFIXO)
            aAdd(_aItens,SE2->E2_NUM)
            aAdd(_aItens,SE2->E2_PARCELA)
            aAdd(_aItens,SE2->E2_TIPO)
            aAdd(_aItens,SE2->E2_NATUREZ)
            aAdd(_aItens,SE2->E2_FORNECE)
            aAdd(_aItens,SE2->E2_LOJA   )
            aAdd(_aItens,DToC(SE2->E2_EMISSAO))
            aAdd(_aItens,DToC(SE2->E2_VENCREA))
            aAdd(_aItens,AllTrim(TRANSFORM(SE2->E2_SALDO*If(SE2->E2_TIPO="NDF",-1,1),"@E 999,999,999,999.99")))//11
            aAdd(_aItens,AllTrim(TRANSFORM(SE2->E2_DECRESC,"@E 999,999,999,999.99")))//12
            aAdd(_aItens,SE2->E2_HIST   )//13
            aAdd(_aItens,"Liberado com sucesso")  //14
            aAdd(_aItens,SE2->E2_SALDO*If(SE2->E2_TIPO="NDF",-1,1))//15
            aAdd(_aItens,SE2->E2_DECRESC)//16
            aAdd(_aTLinhas,_aItens)

         EndIf
      Next

      //**********************  GERACAO DA FATURA AQUI *************************************************
      _lRet := AOMS148SE(aTitulos,aTitAlt[1,1])
      //**********************  GERACAO DA FATURA AQUI *************************************************
   EndIf
EndIf

//Monta aheader
aAdd(_aCab,"")//01
aAdd(_aSize,5)
aAdd(_aCab,Getsx3cache("E2_PREFIXO","X3_TITULO"))//02
aAdd(_aSize,5)
aAdd(_aCab,Getsx3cache("E2_NUM"    ,"X3_TITULO"))//03
aAdd(_aSize,12)
aAdd(_aCab,Getsx3cache("E2_PARCELA","X3_TITULO"))//04
aAdd(_aSize,5)
aAdd(_aCab,Getsx3cache("E2_TIPO"   ,"X3_TITULO"))//05
aAdd(_aSize,5)
aAdd(_aCab,Getsx3cache("E2_NATUREZ","X3_TITULO"))//06
aAdd(_aSize,8)
aAdd(_aCab,Getsx3cache("E2_FORNECE","X3_TITULO"))//07
aAdd(_aSize,35)
aAdd(_aCab,Getsx3cache("E2_LOJA"   ,"X3_TITULO"))//08
aAdd(_aSize,5)
aAdd(_aCab,"Emissão")//09
aAdd(_aSize,40)
aAdd(_aCab,Getsx3cache("E2_VENCREA" ,"X3_TITULO"))//10
aAdd(_aSize,40)
aAdd(_aCab,"Valor Total")//11
aAdd(_aSize,40)
aAdd(_aCab,Getsx3cache("E2_SDDECRE","X3_TITULO"))//12
aAdd(_aSize,30)
aAdd(_aCab,Getsx3cache("E2_HIST"   ,"X3_TITULO"))//13
aAdd(_aSize,70)
aAdd(_aCab,"Resultado / Histórico")//14
aAdd(_aSize,70)

If Len(_aTLinhas) > 0
   
   nPosResu := Len(_aCab) //Posiçao do "Resultado"

   For T:= 1 To Len(_aTLinhas)
      If !_aTLinhas[T,1]
         _cErro += _aTLinhas[T,nPosResu]
         _lRetorno := .F.
      EndIf
   Next

Else
   _cErro := "Nenhum registro localizado"
   _lRetorno  := .F.
EndIf

Return _lRetorno

/*
===============================================================================================================================
Programa----------: AOMS148SE()
Autor-------------: Igor Melgaço
Data da Criacao---: 03/04/2025
Descrição---------: Gera os Faturas dos Transportadores marcaods
Parametros--------: oProc,_aTitulos,nRecSE2
Retorno-----------: _lRet
===============================================================================================================================
*/
Static Function AOMS148SE(_aTitulos As Array,nRecSE2 As Numeric) As Logical

Local _nModAux   As Numeric
Local _cModAux   As Character
Local _lRet      As Logical
Local _cNatureza As Character
Local _cFornece  As Character
Local _cLoja     As Character
Local _cCondicao As Character
Local _dDtorig   As Date
Local _nTit      As Numeric
Local _nDesconto As Numeric
Local _cHistoric As Character

_nModAux   := nModulo
_cModAux   := cModulo
_lRet      := .T.
_cNatureza := SuperGetMV("IT_NATFAT",.F.,"231007")
_cFornece  := TRBF->E2_FORNECE
_cLoja     := TRBF->E2_LOJA 
_cCondicao := "001" //, nSeq
_dDtorig   := dDataBase
_nTit      := 0
_nDesconto := 0
_cHistoric := ""

If DAY(dDataBase) >  23//24 a 31
   _dDtVenc := CTOD("08/"+StrZero( Month(Date())+1 , 2 ) +'/'+ StrZero( Year(Date()) , 4 ))
ElseIf DAY(dDataBase) >  8 //9 a 23
   _dDtVenc := CTOD("23/"+StrZero( Month(Date())   , 2 ) +'/'+ StrZero( Year(Date()) , 4 ))
Else//1 a 8
   _dDtVenc := CTOD("08/"+StrZero( Month(Date())   , 2 ) +'/'+ StrZero( Year(Date()) , 4 ))
EndIf

cUserName := cUserName

_aItens := {} //_lEmail FATURA

aAdd(_aItens,.T.       ) //01
aAdd(_aItens,"MAN"     ) //02
aAdd(_aItens,""        ) //03  PREENCHIDO APOS A GERAÇÃO
aAdd(_aItens,'01'      ) //04
aAdd(_aItens,"FT "     ) //05
aAdd(_aItens,_cNatureza) //06
aAdd(_aItens,_cFornece ) //07
aAdd(_aItens,_cLoja    ) //08
aAdd(_aItens,DToC(DataValida( _dDtVenc ))) //09
aAdd(_aItens,DToC(DataValida( _dDtVenc ))) //10
aAdd(_aItens,""        ) //11  PREENCHIDO APOS A GERAÇÃO // 11
aAdd(_aItens,AllTrim(TRANSFORM(_nDesconto,"@E 999,999,999,999.99"))) //12
aAdd(_aItens,_cHistoric) //13
aAdd(_aItens,""        ) //14 - _cErro
aAdd(_aItens,0         ) //15 - SE2->E2_VALOR-_nDesconto
aAdd(_aItens,_nDesconto) //16

cLog       := ""
_cFatura2  := Soma1(GetMV( 'MV_NUMFATP' ,, '0' ))
_cChaveFAT := cFilAnt + "MAN" + _cFatura2  + '01' + "FT " + _cFornece+_cLoja

SE2->( DBSetOrder(1) )
While SE2->( DBSeek( _cChaveFAT ) )
   cLog += " / Achou: [ "+_cChaveFAT+" ] "

   PutMV("MV_NUMFATP", _cFatura2)
   
   _cFatura2  := Soma1(_cFatura2)
   _cChaveFAT := cFilAnt + "MAN" + _cFatura2  + '01' + "FT " + _cFornece+_cLoja
EndDo

//Cria Fatura no financeiro
aArray := {}

aAdd(aArray,"MAN")     //01
aAdd(aArray,"FT" )     //02
aAdd(aArray,' ')       //03 //Em branco para seguir sequência de fatura do Protheus
aAdd(aArray,_cNatureza)//04
aAdd(aArray,_dDtIni)   //05
aAdd(aArray,_dDtFim)   //06
aAdd(aArray,_cFornece) //07
aAdd(aArray,"    ")    //08 //Loja em branco para trazer todos os títulos do fornecedor
aAdd(aArray,_cFornece) //09
aAdd(aArray,_cLoja)    //10
aAdd(aArray,_cCondicao)//11
aAdd(aArray,1)         //12
aAdd(aArray,_aTitulos) //13
aAdd(aArray,_nDesconto)//14
aAdd(aArray,0)         //15

nModulo	   := 6
cModulo	   := "FIN"
lMsErroAuto := .F.
dDataBase   := DataValida( _dDtVenc )

SE2->(DBGoTo( nRecSE2 ))//POSICIONA NO PRIMEIRO TITULO DA LISTA

Begin Sequence

   BEGIN TRANSACTION
      DBSelectArea( "SE5" )
      MsExecAuto( { |x,y| FINA290(x,y)},3,aArray,) //INCLUSAO DA FATURA

      //cParaVernoDEBUG:=GetMV( 'MV_NUMFATP')

      _cErro := "FATURA Gerada com Sucesso"

      If lMsErroAuto

         _cErro     := AllTrim(MOSTRAERRO())//GETTEMPPATH()))
         _cErro     := "Não Gerou. Acesse Ver Resultado: " + CHR(13) + CHR(10) + AllTrim(_cErro)
         _aItens[1] := .F.
         _lRet      := .F.

         DisarmTransaction()

      Else

         _cChaveFAT := cFilAnt + "MAN" + _cFatura2  + '01' + "FT " + _cFornece + _cLoja

         SE2->( DBSetOrder(1) )
         If SE2->( DBSeek( _cChaveFAT ) )

            SE2->( RecLock('SE2',.F.) )
            SE2->E2_VENCTO	 := _dDtVenc
            SE2->E2_VENCORI := _dDtVenc
            SE2->E2_VENCREA := DataValida( _dDtVenc )
            SE2->E2_HIST    := _cHistoric
            SE2->E2_ORIGEM  := "AOMS148"
            SE2->( MSUnLock() )

            _aItens[03] := _cFatura2
            _aItens[11] := AllTrim(Transform(SE2->E2_VALOR-SE2->E2_SDDECRE,"@E 999,999,999,999.99"))
            _aItens[15] := SE2->E2_VALOR - _nDesconto
            
            aAdd(_aChaveFAT, SE2->(RECNO()) )

            AOMSGRVFI8(_aTitulos)

         Else

            _cChaveFAT  := cFilAnt + "MAN [ " + _cFatura2  + ' ] 01' + "FT " + _cFornece + _cLoja
            _cErro      := "NÃO GEROU FATURA. Acesse Ver Resultado: "+CHR(13)+CHR(10)+"Titulo da fatura não localizado: "+_cChaveFAT+" / MV_NUMFATP = [ "+GetMV('MV_NUMFATP')+" ] "+cLog
            _aItens[01] := .F.
            _aItens[03] := _cFatura2
            _cChaveFAT  := ""
            _lRet       := .F.

            DisarmTransaction()
            Break

         EndIf

      EndIf

   END TRANSACTION
End Sequence

DBSelectArea("SE5")
DBSetOrder(2)  // FILIAL + TIPODOC + PREFIXO + NUMERO + PARCELA

For _nTit := 1 To Len(_aTitulos)
   If SE5->(DBSeek(xFilial("SE5") + "DC" + _aTitulos[_nTit][1] + _aTitulos[_nTit][2] + _aTitulos[_nTit][3] + _aTitulos[_nTit][4] + DToS(dDataBase) + _aTitulos[_nTit][6] + _aTitulos[_nTit][7]))		
      RecLock("SE5",.F.)
      SE5->E5_TPDESC := "I"
      SE5->(MSUnLock())
   EndIf
Next _nTit
SE5->(DBCloseArea())

_aItens[14] := _cErro //14

aAdd(_aTLinhas,_aItens)

nModulo   := _nModAux
cModulo   := _cModAux
dDataBase := _dDtorig

Return _lRet
