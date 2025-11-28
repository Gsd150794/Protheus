/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex          |05/08/2025| Chamado 37652. Ajustes para melhorar e flexibilizar a manutenção dos itens para gerar os PVs.
Lucas Borges  |17/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
Jose Gavetti  |10/10/2025| Chamado 52364. Inserido campo C5_I_CDUSU para ser enviado no cabeçalho do Pedido.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include 'FWMVCDef.ch'

/*
===============================================================================================================================
Programa----------: AOMS132
Autor-------------: Julio de Paula Paz
Data da Criacao---: 07/01/2022
Descrição---------: Rotina de Manutenção no Cadastro do Pré-Pedido de Vendas Com base no Pedido de Compras dos Clientes.
                    Chamado 37652.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS132

Local _oBrowse     As object
Local _aNoFields   As array
Local _cCampo      As char
Local _nI          As numeric

Private _cTitulo           As char
Private aHeader            As array
Private aCols              As array
Private _cCampos_F3_LSTTPA As char
Private _cCpos_Nao_Usados  As char

_cCampos_F3_LSTTPA:="ZBF_AGENDA/ZBC_AGENDA/ZBE_AGENDA"//Variaval usara no F3 do tipo de agendamento "LSTTPA"
_cCpos_Nao_Usados :="ZBF_PEDCOM/ZBF_FILGPV/ZBF_PEDCLI/ZBF_CLIENT/ZBF_LOJACL/ZBF_CHAVE/ZBF_PLPROT/ZBF_QTDLIB/ZBF_QTDLB2/ZBF_ENTREG"

// Inicializa variaveis de memória SC5 e ACols para simular pedido de vendas.
aHeader   := {}
aCols     := {}
_aNoFields := {"C5_REC_WT","C5_ALI_WT","C5_I_DESCO","C5_I_NOUSU","C5_NOMMOT","C5_I_V4NOM","C5_I_V5NOM","C5_I_DTAB"}

RegToMemory( "SC5", .F., .F. )

FillGetDados(1     ,"SC5"   ,1       ,          ,             ,{||.T.}, _aNoFields ,,,,,.T.)

//                     1            2         3           4          5        6        7       8       9       10
// aAdd(aHeader,{trim(x3_titulo),x3_campo,x3_picture,x3_tamanho,x3_decimal,x3_valid,x3_usado,x3_tipo, x3_f3,x3_context})
For _nI := 1 To Len(aHeader)
   If ! AllTrim( aHeader[_nI,2]) $ "C5_REC_WT/C5_ALI_WT/C5_I_DESCO/C5_I_NOUSU/C5_NOMMOT/C5_I_V4NOM/C5_I_V5NOM/C5_I_DTAB"
      &("M->" + aHeader[_nI,2]) := CriaVar(aHeader[_nI,2])
   EndIf
Next _nI
aHeader := {}
aCols   := {}

// Campos que não serão exibidos na msgetdados.
_aNoFields := {"C6_SLDALIB",;
               "C6_INFAD",;
               "C6_I_QESP",;
               "C6_GRADE",;
               "C6_TPOP",;
               "C6_TPCONTR",;
               "C6_REGWMS",;
               "C6_TPDEDUZ",;
               "C6_MOTDED",;
               "C6_I_DIFPE",;
               "C6_VDMOST",;
               "C6_RATEIO",;
               "C6_INTROT",;
               "C6_TPPROD"}

// Montagem do aheader
FillGetDados(1     ,"SC6"   ,1       ,          ,             ,{||.T.}    ,_aNoFields ,,,,,.T.)
aAdd(aCols,Array(Len(aHeader)+1))

For _nI := 1 To Len(aHeader)
   _cCampo := AllTrim(aHeader[_nI,2])

   If (aHeader[_nI,10] # "V" .And. ! (_cCampo $ "C6_QTDLIB/C6_ALI_WT/C6_REC_WT"))
      aCols[Len(aCols)][_nI] := CriaVar(_cCampo)
   EndIf
Next _nI

aCols[Len(aCols)][Len(aHeader)+1] := .F.

// Rotina Principal
_cTitulo := "Cadastro de Pré-Pedido de Vendas com Base no Pedido de Compras dos Clientes"
_oBrowse := FWmBrowse():New()
_oBrowse:SetAlias( 'ZBC' )
_oBrowse:SetMenuDef('AOMS132')
_oBrowse:SetDescription( _cTitulo )

_oBrowse:AddLegend('Posicione("ZBF",3,xFilial("ZBF")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL),"ZBF_PVPROT")<>" "',"BLACK", "Pedidos do protheus gerados" )
_oBrowse:AddLegend('Posicione("ZBF",3,xFilial("ZBF")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL),"ZBF_PEDCOM")= " "',"GREEN", "Pre-pedidos não gerados"     )
_oBrowse:AddLegend('Posicione("ZBF",3,xFilial("ZBF")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL),"ZBF_PEDCOM")<>" "',"RED"  , "Pre-pedidos gerados"         )

_oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MenuDef()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 07/01/2022
Descrição---------: Define o Menu da Rotina.
Parametros--------: Nenhum
Retorno-----------: aRotina
===============================================================================================================================
*/
Static Function MenuDef() As array

Local aRotina := {} As array

ADD OPTION aRotina Title '1-Incluir PV Cliente'                         Action 'VIEWDEF.AOMS132' OPERATION 3 ACCESS 0
ADD OPTION aRotina Title '2-Gerar Pre-Pedidos Vendas'                   Action 'U_AOMS132I'      OPERATION 2 ACCESS 0
ADD OPTION aRotina Title '3-Manutenção / Efetiva Pre-PVs'               Action 'U_AOMS132N'      OPERATION 2 ACCESS 0
ADD OPTION aRotina Title '4-Visualiza PVs Gerados / Efetiva Pre-PVs'    Action 'U_AOMS132E'      OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Visualizar PV Cliente'                        Action 'VIEWDEF.AOMS132' OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Alterar PV Cliente'                           Action 'VIEWDEF.AOMS132' OPERATION 4 ACCESS 0
ADD OPTION aRotina Title 'Excluir PV Cliente'                           Action 'VIEWDEF.AOMS132' OPERATION 5 ACCESS 0
ADD OPTION aRotina Title 'Copiar PV Cliente'                            Action 'VIEWDEF.AOMS132' OPERATION 9 Access 0
ADD OPTION aRotina Title 'Lista Tipos de Veiculos Cliente'              Action 'U_AOMS132T'      OPERATION 4 ACCESS 0

Return aRotina

/*
===============================================================================================================================
Programa----------: ModelDef()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 07/01/2022
Descrição---------: Define o Modelo de Dados.
Parametros--------: Nenhum
Retorno-----------: _oModel
===============================================================================================================================
*/
Static Function ModelDef() As object
Local _oStruZBC As object
Local _oStruZBD As object
Local _oModel As object

_oStruZBC := FWFormStruct( 1, 'ZBC', /*bAvalCampo*/, /*lViewUsado*/ )
_oStruZBD := FWFormStruct( 1, 'ZBD', /*bAvalCampo*/, /*lViewUsado*/ )

// Cria o objeto do Modelo de Dados
_oModel := MPFormModel():New( 'AOMS132M', /*bPreValidacao*/, {|oModel| U_AOMS132V("BOTAO_OK",oModel)} /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )

// Adiciona ao modelo uma estrutura de formulário de edição por campo
_oModel:AddFields( 'ZBCMASTER', /*cOwner*/, _oStruZBC )

// Adiciona ao modelo uma estrutura de formulário de edição por grid
_oModel:AddGrid( 'ZBDDETAIL', 'ZBCMASTER', _oStruZBD, /*bLinePre*/, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/, /*BLoad*/ )

// Faz relaciomaneto entre os compomentes do model
_oModel:SetRelation( 'ZBDDETAIL', { { 'ZBD_FILIAL', 'xFilial( "ZBD" )' }, { 'ZBD_CHAVE', 'ZBC_CHAVE' } }, ZBD->( IndexKey( 1 ) ) )

// configurando a chave primária.
_oModel:SetPrimaryKey({"ZBD_FILIAL", "ZBD_PEDCOM", "ZBD_CLIENT","ZBD_LOJACL","ZBD_PRODUT"})

//NÃO INCIA ESSA LISTA DE CAMPOS NO BOTÃO COPIA
_oModel:GetModel( 'ZBCMASTER' ):AFLDNOCOPY := { "ZBC_PEDCOM" } //CAPA
//_oModel:GetModel( 'ZBDDETAIL' ):AFLDNOCOPY := { "ZBD_PEDCOM" } //DETALHE SE PRECISAR

// Liga o controle de nao repeticao de linha
_oModel:GetModel( 'ZBDDETAIL' ):SetUniqueLine( { 'ZBD_PRODUT' } )

// Adiciona a descricao do Modelo de Dados
_oModel:SetDescription( 'Pedidos de Compras dos Clientes' )

// Adiciona a descricao do Componente do Modelo de Dados
_oModel:GetModel( 'ZBCMASTER' ):SetDescription( 'Pedido de Compra do Cliente' )
_oModel:GetModel( 'ZBDDETAIL' ):SetDescription( 'Itens do Pedido de Compra do Cliente')

//Define validação inical do modelo                                       |
_oModel:SetVldActivate( { |_oModel|  U_AOMS132V("PRE-VALID",_oModel)}  )

Return _oModel

/*
===============================================================================================================================
Programa----------: ViewDef()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 07/01/2022
Descrição---------: Define View/Exibição de Dados.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ViewDef()

Local _oStruZBC As object
Local _oStruZBD As object
Local _oModel   As object
Local oView     As object

_oStruZBC := FWFormStruct( 2, 'ZBC' )
_oStruZBD := FWFormStruct( 2, 'ZBD' )
_oModel   := FWLoadModel( 'AOMS132' )

// Remove da tela esses Campos dos itens
_oStruZBD:RemoveField('ZBD_QTDLIB')
_oStruZBD:RemoveField('ZBD_QTDLB2')
_oStruZBD:RemoveField('ZBD_OPER'  )
_oStruZBD:RemoveField('ZBD_ENTREG')
_oStruZBD:RemoveField('ZBD_PEDCLI')
_oStruZBD:RemoveField('ZBD_PEDCOM')
_oStruZBD:RemoveField('ZBD_CLIENT')
_oStruZBD:RemoveField('ZBD_LOJACL')
_oStruZBD:RemoveField('ZBD_CHAVE' )

// Cria o objeto de View
oView := FWFormView():New()

// Define qual o Modelo de dados será utilizado
oView:SetModel( _oModel )

//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
oView:AddField( 'VIEW_ZBC', _oStruZBC, 'ZBCMASTER' )

//Adiciona no nosso View um controle do tipo FormGrid(antiga newgetdados)
oView:AddGrid(  'VIEW_ZBD', _oStruZBD, 'ZBDDETAIL' )

// Criar um "box" horizontal para receber algum elemento da view
oView:CreateHorizontalBox( 'SUPERIOR', 30 )
oView:CreateHorizontalBox( 'INFERIOR', 70 )

// Relaciona o ID da View com o "box" para exibicao
oView:SetOwnerView( 'VIEW_ZBC', 'SUPERIOR' )
oView:SetOwnerView( 'VIEW_ZBD', 'INFERIOR' )

// Define campos que terao Auto Incremento
oView:AddIncrementField( 'VIEW_ZBD', 'ZBD_ITEM' )

// Liga a identificacao do componente
oView:EnableTitleView('VIEW_ZBD',_cTitulo)

// Liga a Edição de Campos na FormGrid
oView:SetViewProperty( 'VIEW_ZBD', "ENABLEDGRIDDETAIL", { 50 } )

Return oView

/*
===============================================================================================================================
Programa----------: AOMS132V
Autor-------------: Julio de Paula Paz
Data da Criacao---: 07/01/2022
Descrição---------: Valida o preenchimento dos dados conforme campo/chamada passado por parâmetro nos X3_VALID tb.
Parametros--------: _cCampo = Campo que chamou a validação.
Retorno-----------: _lRet == .T. = Validação Ok.
                             .F. = não conformidade na validação.
===============================================================================================================================
*/
User Function AOMS132V(_cCampo As char , _oModel As object ,_nLine,_cAction,_cField ) As logical

Local _lRet      As logical
Local _lValidCli As logical
Local _oModelZBD As object
Local _oModelZBC As object
Local _nI        As numeric
Local _nTotLin   As numeric
Local _nOperacao As numeric
Local _nQtd      As numeric
Local _nQtd2     As numeric
Local _nQtdPalet As numeric
Local _nPrcVend  As numeric
Local _nValorTot As numeric
Local _dDtEntreg As date
Local _dDtEntr   As date
Local _cOperac   As char
Local _cCod      As char
Local _cLoja     As char
Local _cPedCom   As char
Local _cCliente  As char
Local _cTabPrc   As char
Local _cVend1    As char
Local _cVend2    As char
Local _cVend3    As char
Local _cVend4    As char
Local _cRede     As char
Local _cTipoVend As char
Local _cTrocaNf  As char
Local _cFilCarre As char
Local _cFilFatur As char
//Local _aTabPrc   As array
Default _oModel := FWModelActive()

_lRet  := .T.
_lValidCli := .F.

Begin Sequence//Não retirar

If _cCampo == "#QUANTIDADE"

   _nQtdeAtual:=_nQtdeTotal-_nQtdeNova

   _nQtd1     :=AOMS132CNV(_nQtdeNova, 2 , 1,(_cTRBZBF)->ZBF_PRODUT)
   _nQtdNPalet:=AOMS132CT((_cTRBZBF)->ZBF_PRODUT,_nQtd1)

   _nQtd1     :=AOMS132CNV(_nQtdeAtual, 2 , 1,(_cTRBZBF)->ZBF_PRODUT)
   _nQtdAPalet:=AOMS132CT((_cTRBZBF)->ZBF_PRODUT,_nQtd1)

   _oQtdeAtual:Refresh()
   _oPalAtual:Refresh()
   _oPalNova:Refresh()
   _lRet := .T.

   Break//SAI AQUI PARA NÃO VALIDAR MAIS NADA NESSA CHAMADA ***********************************************

EndIf

_nOperacao  := _oModel:GetOperation()

If _cCampo == "PRE-VALID" .And. (_nOperacao = MODEL_OPERATION_UPDATE .Or. _nOperacao = MODEL_OPERATION_DELETE)

   ZBF->(DBSetOrder(3))
   ZBE->(DBSetOrder(2)) // ZBE_FILIAL+ZBE_PEDCOM+ZBE_CLIENT+ZBE_LOJACL
   If ZBE->(MsSeek(xFilial("ZBE")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL))) .AND.;
      ZBF->(MsSeek(xFilial("ZBF")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL)))
      Help( ,, 'Atenção'+" ["+DToC(Date())+"] ["+TIME()+"] AOMS132_001",, 'Para este pedido de compras já foi gerado pré-pedidos de vendas e não pode ser alterado.', 1, 0 )
      _lRet := .F.
   EndIf
   Break//SAI AQUI PARA NÃO VALIDAR MAIS NADA NESSA CHAMADA do _oModel:SetVldActivate( { |_oModel|  U_AOMS132V("PRE-VALID",_oModel)}  )

EndIf

_cCod     := CriaVar('ZBC_CLIENT')
_cLoja    := CriaVar('ZBC_LOJACL')
_oModelZBD:= _oModel:GetModel('ZBDDETAIL')
_oModelZBC:= _oModel:GetModel('ZBCMASTER')

If _cCampo == "BOTAO_OK"
   If _nOperacao = MODEL_OPERATION_DELETE
      _cPedCompra := _oModelZBC:GetValue('ZBC_PEDCOM')

      If !Empty(_cPedCompra)
         ZBF->(DBSetOrder(1))
         If ZBF->(MsSeek(xFilial("ZBF")+_cPedCompra))//ZBC_PEDCOM
            Help( ,, 'Atenção'+" ["+DToC(Date())+"] ["+TIME()+"] AOMS132_002",, 'Este pedido de compras já está vinculado a um pré-pedido de vendas e não pode ser excluido.', 1, 0 )
            _lRet := .F.
            Break
         EndIf
      EndIf
   EndIf
EndIf

If _nOperacao <> MODEL_OPERATION_UPDATE .And. _nOperacao <> MODEL_OPERATION_INSERT
   Break//SAI SE VISUALIZAR OU DELETAR
EndIf

If _cCampo == "ZBC_AGENDA" // TIPO DE AGENDAMENTO DO ZBF

   If !U_TipoEntrega(M->ZBC_AGENDA,.T.) .Or. Empty(M->ZBC_AGENDA)

      _lRet:=.F.

   ElseIf MONTH(Date()) != 12 .And.  M->ZBC_AGENDA = 'P'

      M->ZBC_DTENT := SToD(AllTrim(Str((YEAR(Date())+1)))+"0101")-1

   ElseIf MONTH(Date()) = 12 .And.  M->ZBC_AGENDA = 'P'

      M->ZBC_DTENT := SToD(AllTrim(Str((YEAR(Date())+2)))+"0101")-1

   ElseIf !Empty(M->ZBC_AGENDA) .And. M->ZBC_AGENDA $ 'I,O'
         //                   OMSVLDENT(_ddent,_cclient     ,_cloja       ,_cfilft     ,_cpedido,_nret,_lshow,_cFilCarreg,_cOperPedV   ,_cTipoVenda ,_lAchouZG5,_cRegra,_cLocalEmb,_lValSC5)
      M->ZBC_DTENT:=Date()+U_OmsVlDent(      ,M->ZBC_CLIENT,M->ZBC_LOJACL,M->ZBC_FLFNC,""      ,1    ,.F.   ,           ,M->ZBC_OPERAC,M->ZBC_TPVEN,          ,       ,          ,.F.)

   EndIf
   _oModelZBC:LoadValue('ZBC_DTENT',M->ZBC_DTENT)

ElseIf _cCampo == "ZBC_TRCNF"

   If !Pertence("SN",M->ZBC_TRCNF)
      _lRet := .F.
      Break
   EndIf
   If Empty(M->ZBC_FLFNC)
      M->ZBC_FLFNC:=cFilAnt
   EndIf
   If M->ZBC_TRCNF = 'S' .And. M->ZBC_FILFT == M->ZBC_FLFNC
      M->ZBC_FILFT:='  '
   ElseIf M->ZBC_TRCNF = 'N'
      M->ZBC_FILFT:=M->ZBC_FLFNC
   EndIf
   _oModelZBC:LoadValue('ZBC_FLFNC',M->ZBC_FLFNC)
   _oModelZBC:LoadValue('ZBC_FILFT',M->ZBC_FILFT)

ElseIf _cCampo == "ZBC_CLIENT"
   _cCod:= _oModelZBC:GetValue('ZBC_CLIENT')
   If ! ExistCpo("SA1", _cCod)
      _lRet := .F.
      Break
   EndIf
   _lValidCli := .T.

ElseIf _cCampo == "ZBC_LOJACL"
   _cCod     := _oModelZBC:GetValue('ZBC_CLIENT')
   _cLoja    := _oModelZBC:GetValue('ZBC_LOJACL')

   If ! ExistCpo("SA1", _cCod + _cLoja)
      _lRet := .F.
      Break
   EndIf
   _lValidCli := .T.

ElseIf _cCampo == "ZBD_PRODUT"

   _cCod     := _oModelZBD:GetValue('ZBD_PRODUT')
   If ! ExistCpo("SB1", _cCod)
      _lRet := .F.
      Break
   EndIf
   SB1->(DBSetOrder(1))
   SB1->(MsSeek(xFilial("SB1")+_cCod))

   If SB1->B1_I_CXPAL = 0
      Help( ,, 'Atenção'+" ["+DToC(Date())+"] ["+TIME()+"] AOMS132_003",, 'A quantidades por palete não foi informada para este produto. (B1_I_CXPAL)', 1, 0 )
      _lRet := .F.
      Break
   EndIf

   _oModelZBD:LoadValue('ZBD_SEGUM' ,SB1->B1_SEGUM)
   _oModelZBD:LoadValue('ZBD_UM'    ,SB1->B1_UM)
   _oModelZBD:LoadValue('ZBD_LOCAL' ,SB1->B1_LOCPAD)
   _oModelZBD:LoadValue('ZBD_DESCRI',SB1->B1_DESC)
   U_AOMS132V("#ZBD_QTDPAL")

ElseIf _cCampo == "ZBD_UNSVEN" // quantidade segunda unidade de medida #UNSVEN

   _nQtd2   := _oModelZBD:GetValue('ZBD_UNSVEN')
   _nPrcVend:= _oModelZBD:GetValue('ZBD_PRCVEN')

   If _nQtd2 == 0
      Break
   EndIf

   _cCod := _oModelZBD:GetValue('ZBD_PRODUT')
   SB1->(DBSetOrder(1))
   SB1->(MsSeek(xFilial("SB1")+_cCod))

   _nQtd     := AOMS132CNV(_nQtd2, 2 , 1) //CONVERSÃO 2UM PARA 1UM
   _cUMPal   :=""  //Preenchido na rotina AOMS132CT ()
   _cUMPal2UM:=""  //Preenchido na rotina AOMS132CT ()
   _nQtdPalet:= AOMS132CT(_cCod,_nQtd)  //CALCULO DA QUANTIDADE DE PALETES
   If !Empty(_cUMPal2UM)
      _cUMPal:=_cUMPal2UM
   EndIf

   If _nQtdPalet <> Int(_nQtdPalet)
      Help( ,, 'Atenção'+" ["+DToC(Date())+"] ["+TIME()+"] AOMS132_004",, 'A quantidade informada na primeia unidade de medida não é multipla das quantidades por palete para este item. '+_cUMPal+" por palete.", 1, 0 )
      _lRet := .F.
      Break
   EndIf

   _nValorTot := _nPrcVend * _nQtd

   _oModelZBD:LoadValue('ZBD_QTDVEN', _nQtd)
   _oModelZBD:LoadValue('ZBD_QTDPAL', _nQtdPalet)
   _oModelZBD:LoadValue('ZBD_VALOR' , _nValorTot)

ElseIf _cCampo == "ZBD_QTDVEN"  // QUANTIDADE PRIMEIRA UNIDADE

   _nQtd     := _oModelZBD:GetValue('ZBD_QTDVEN')
   _nPrcVend := _oModelZBD:GetValue('ZBD_PRCVEN')

   If _nQtd = 0
      Help( ,, 'Atenção'+" ["+DToC(Date())+"] ["+TIME()+"] AOMS132_005",, 'O preenchimento da quantidade do item na primeira unidade de medida é obrigatório.', 1, 0 )
      _lRet := .F.
      Break
   EndIf

   _cCod:= _oModelZBD:GetValue('ZBD_PRODUT')
   SB1->(DBSetOrder(1))
   SB1->(MsSeek(xFilial("SB1")+_cCod))

   _nQtd2    := AOMS132CNV(_nQtd, 1 , 2)//CONVERSÃO 1UM PARA 2UM
   _cUMPal   := ""//Preenchido na rotina AOMS132CT ()
   _cUMPal1UM:= ""//Preenchido na rotina AOMS132CT ()
   _nQtdPalet:= AOMS132CT(_cCod,_nQtd)  //CALCULO DA QUANTIDADE DE PALETES
   If !Empty(_cUMPal1UM)
      _cUMPal:=_cUMPal1UM
   EndIf
   If _nQtdPalet <> Int(_nQtdPalet)
      Help( ,, 'Atenção'+" ["+DToC(Date())+"] ["+TIME()+"] AOMS132_007",, 'A quantidade informada na primeira unidade de medida não é multipla das quantidades por palete para este item. '+_cUMPal+" por palete.", 1, 0 )
      _lRet := .F.
      Break
   EndIf

   _nValorTot := _nPrcVend * _nQtd
   _oModelZBD:LoadValue('ZBD_UNSVEN', _nQtd2)
   _oModelZBD:LoadValue('ZBD_QTDPAL', _nQtdPalet)
   _oModelZBD:LoadValue('ZBD_VALOR' , _nValorTot)

ElseIf _cCampo == "#ZBD_QTDPAL" // QUANTIDADE DE #PALLET#

   _nQtdPalet:= _oModelZBD:GetValue('ZBD_QTDPAL')
   _nPrcVend := _oModelZBD:GetValue('ZBD_PRCVEN')

   If _nQtdPalet = 0
      Help( ,, 'Atenção'+" ["+DToC(Date())+"] ["+TIME()+"] AOMS132_0P5",, 'O preenchimento da quantidade de Pallet do item é obrigatório.', 1, 0 )
      _lRet := .F.
      Break
   EndIf

   _cCod:= _oModelZBD:GetValue('ZBD_PRODUT')
   SB1->(DBSetOrder(1))
   SB1->(MsSeek(xFilial("SB1")+_cCod))

   _nQtd := AOMS132CT(_cCod,_nQtdPalet,.T.)//  ** CALCULO DA 1UM QUANTIDADE
   _nQtd2:= AOMS132CNV(_nQtd, 1 , 2)//CALCULO DA 2 UM QUANTIDADE

   _nValorTot := _nPrcVend * _nQtd
   _oModelZBD:LoadValue('ZBD_QTDVEN', _nQtd)
   _oModelZBD:LoadValue('ZBD_UNSVEN', _nQtd2)
   _oModelZBD:LoadValue('ZBD_VALOR' , _nValorTot)


ElseIf _cCampo == "ZBD_PRCVEN"  //preço unitário

   _nPrcVend := _oModelZBD:GetValue('ZBD_PRCVEN')
   _nQtd     := _oModelZBD:GetValue('ZBD_QTDVEN')

   If _nPrcVend == 0
      Help( ,, 'Atenção'+" ["+DToC(Date())+"] ["+TIME()+"] AOMS132_008",, 'O preenchimento do preço unitário do item é obrigatório.', 1, 0 )
      _lRet := .F.
      Break
   EndIf

   _nValorTot := _nPrcVend * _nQtd
   _oModelZBD:LoadValue('ZBD_VALOR', _nValorTot)

EndIf

If _lValidCli
   SA1->(DBSetOrder(1))
   SA3->(DBSetOrder(1))

   If _cCampo == "ZBC_CLIENT"
      SA1->(MsSeek(xFilial("SA1")+_cCod))
   Else
      SA1->(MsSeek(xFilial("SA1")+_cCod+_cLoja))
   EndIf

   _cVend1  := SA1->A1_VEND
   _cVend2  := Space(6)
   _cVend3  := Space(6)
   _cVend4  := Space(6)
   _cRede   := SA1->A1_GRPVEN
   _cOperac := _oModelZBC:GetValue('ZBC_OPERAC')

   _oModelZBC:LoadValue('ZBC_NOME'  , SA1->A1_NOME)
   _oModelZBC:LoadValue('ZBC_FANTAS', SA1->A1_NREDUZ)
   _oModelZBC:LoadValue('ZBC_EST'   , SA1->A1_EST)
   _oModelZBC:LoadValue('ZBC_CMUN'  , SA1->A1_COD_MUN)
   _oModelZBC:LoadValue('ZBC_MUN'   , SA1->A1_MUN)
   _oModelZBC:LoadValue('ZBC_CEP'   , SA1->A1_CEP)
   _oModelZBC:LoadValue('ZBC_CLENTR', SA1->A1_COD)
   _oModelZBC:LoadValue('ZBC_LOJAEN', SA1->A1_LOJA)
   _oModelZBC:LoadValue('ZBC_ENDENT', SA1->A1_ENDENT)
   _oModelZBC:LoadValue('ZBC_BAIREN', SA1->A1_BAIRROE)
   _oModelZBC:LoadValue('ZBC_DDD'   , SA1->A1_DDD)
   _oModelZBC:LoadValue('ZBC_TELEFO', LEFT(SA1->A1_TEL,Len(ZBC->ZBC_TELEFO)))
   _oModelZBC:LoadValue('ZBC_VEND1' , SA1->A1_VEND)        //    - Vendedor

   If SA3->(MsSeek(xFilial("SA3")+SA1->A1_VEND))
      _oModelZBC:LoadValue('ZBC_VEND2' , SA3->A3_SUPER)    //   - Coordenador
      _oModelZBC:LoadValue('ZBC_VEND3' , SA3->A3_GEREN)    //   - Gerente
      _oModelZBC:LoadValue('ZBC_VEND4' , SA3->A3_I_SUPE)   //  - Supervisor
      _cVend2 := SA3->A3_SUPER
      _cVend3 := SA3->A3_GEREN
      _cVend4 := SA3->A3_I_SUPE
   EndIf

   _cTabPrc := SA1->A1_TABELA
   If ! Empty(SA1->A1_TABELA)
      _oModelZBC:LoadValue('ZBC_TABPRC', SA1->A1_TABELA)
      _oModelZBC:LoadValue('ZBC_DSCTBP', Posicione("DA0",1,xFilial("DA0")+SA1->A1_TABELA, "DA0_DESCRI"))
   EndIf

   If ! Empty(SA1->A1_COND)
      _oModelZBC:LoadValue('ZBC_CONDPG', SA1->A1_COND)     //    = Condição de pagamento
   EndIf

   If Empty(_cOperac)
      _cOperac := "01"
   EndIf

   _oModelZBD:GoLine(1)
   _cLocal1oItem := _oModelZBD:GetValue('ZBD_LOCAL')

   //**********************************************************************
   //As variaveis de memoria M->C5_??????? do SC5 são carregadas AQUI
   M->C5_FILGCT  := _oModelZBC:GetValue('ZBC_FLFNC')
   M->C5_I_FILFT := _oModelZBC:GetValue('ZBC_FILFT')
   M->C5_I_OPER  := _cOperac
   M->C5_I_GRPVE := _cRede
   M->C5_VEND1   := _cVend1
   M->C5_VEND2   := _cVend2
   M->C5_VEND3   := _cVend3
   M->C5_VEND4   := _cVend4
   M->C5_CLIENTE := SA1->A1_COD
   M->C5_LOJACLI := SA1->A1_LOJA
   M->C5_I_TAB   := ""
   M->C5_I_CLIEN := ""
   M->C5_I_LOJEN := ""
   M->C5_I_LOCEM := U_BuscaLocalEmbarque(M->C5_FILGCT,_cLocal1oItem,M->C5_VEND1)//Função no Programa AOMS136.PRW
   //As variaveis de memoria M->C5_??????? do SC5 são carregadas AQUI
   //**********************************************************************

   If Empty(_cTabPrc)
      _aTabPrc := U_ITTABPRC(,,,,,,,.T.)//O Default dos parametros já pega tudo das vaiaveis de memoria (M->C5_???????) do SC5
      If Len(_aTabPrc) > 1
         _cTabPrc := _aTabPrc[1]
         _oModelZBC:LoadValue('ZBC_TABPRC', _cTabPrc)
         _oModelZBC:LoadValue('ZBC_DSCTBP', Posicione("DA0",1,xFilial("DA0")+_cTabPrc, "DA0_DESCRI"))
      EndIf
   EndIf

   _cTipoVend := _oModelZBC:GetValue('ZBC_TPVEN')
   If Empty(_cTipoVend)
      _cTipoVend := "F"
   EndIf
   //                     OMSVLDENT(_ddent,_cclient   ,_cloja      ,_cfilft      ,_cpedido      ,_nret,_lshow,_cFilCarreg ,_cOperPedV,_cTipoVenda,_lAchouZG5,_cRegra,_cLocalEmb,_lValSC5)
   _dDtEntr := Date() + U_OmsVlDent(      ,SA1->A1_COD,SA1->A1_LOJA,M->C5_I_FILFT, M->ZBC_PEDCOM,1    ,.F.   ,M->C5_FILGCT,_cOperac  ,_cTipoVend ,          ,       ,          ,    .F. ) + 1
   _oModelZBC:LoadValue('ZBC_DTENT', _dDtEntr)

   M->C5_I_DTENT := _dDtEntr

   _cPedCom   := _oModelZBC:GetValue('ZBC_PEDCOM')
   _cCliente  := _oModelZBC:GetValue('ZBC_CLIENT')
   _cLoja     := _oModelZBC:GetValue('ZBC_LOJACL')
   _oModelZBC:LoadValue('ZBC_CHAVE', _cPedCom + _cCliente + _cLoja)

ElseIf _cCampo == "BOTAO_OK"

      If _nOperacao == MODEL_OPERATION_UPDATE
         ZBF->(DBSetOrder(3))
         If ZBF->(MsSeek(xFilial("ZBF")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL))) //.And. !Empty(ZBF->ZBF_PVPROT)
            Help( ,, 'Atenção'+" ["+DToC(Date())+"] ["+TIME()+"] AOMS132_009",, 'Para este pedido de compras já foi gerado pré-pedidos de vendas e não pode ser alterado.', 1, 0 )
            _lRet := .F.
            Break
         EndIf
      EndIf

      _cPedCom   := _oModelZBC:GetValue('ZBC_PEDCOM')
      _cCliente  := _oModelZBC:GetValue('ZBC_CLIENT')
      _cLoja     := _oModelZBC:GetValue('ZBC_LOJACL')
      _cOperac   := _oModelZBC:GetValue('ZBC_OPERAC')//Operacao VAI SER UMA SÓ PARA TODOS SO PEDIDOS
      _dDtEntreg := _oModelZBC:GetValue('ZBC_DTENT')
      _cTrocaNf  := _oModelZBC:GetValue('ZBC_TRCNF')
      _cFilCarre := _oModelZBC:GetValue('ZBC_FLFNC')
      _cFilFatur := _oModelZBC:GetValue('ZBC_FILFT')
      M->ZBC_TIPO:= _oModelZBC:GetValue('ZBC_TIPO')
      If Empty(M->ZBC_TIPO)
         M->ZBC_TIPO:= "N"
         _oModelZBC:LoadValue("ZBC_TIPO","N")//NORMAL
      EndIf

      If _nOperacao == MODEL_OPERATION_INSERT
         ZBC->(DBSetOrder(1))//ZBC_FILIAL+ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL
         If ZBC->(MsSeek(xFilial()+_cPedCom+_cCliente+_cLoja))
            Help( ,, 'Atenção'+" ["+DToC(Date())+"] ["+TIME()+"] AOMS132_010",, 'Pedido de compras já cadastrado para esse cliente.', 1, 0 )
            _lRet := .F.
            Break
         EndIf
      EndIf

      _cOperTriangular:= AllTrim(SuperGetMV("IT_OPERTRI",.F.,"05,42"))// Tipos de operações da operação triangular
      If (_cOperac $ _cOperTriangular)
         U_ITMsg("Opercao não pode ser de Triangular: "+_cOperTriangular,'Atenção!',"Troque a operacao para diferente de "+_cOperTriangular,,,,.T.)
         _lRet := .F.
         Break
      EndIf

      _lFob := Posicione("SA1",1,xFilial("SA1") + _cCliente + _cLoja ,"A1_I_FOB")

      If AllTrim(M->ZBC_TPFRET) $ "F/D" .And. !(_cOperac  $ SuperGetMV("IT_OPERFRE",.F.,"")) .And. DToS(Date()) >= DToS(Ctod(SuperGetMV("IT_DTCALCF",.F.,"23/06/2022"))   )
         If !_lFob
            U_ITMsg("Para este Cliente não é permitdo o Tipo de Frete FOB.",'Atencao!',"Para que permita a seleção de Tipo de Frete FOB modifique o respectivo campo no cadastro desse Cliente.",,,,.T.)
            _lRet := .F.
            Break
         EndIf
      EndIf

      If !AOMS132Val(_cTrocaNf,_cFilCarre,_cFilFatur,M->ZBC_TIPO)
         _lRet := .F.
         Break
      EndIf

      _nTotLin := _oModelZBD:Length()
      _cLocal1oItem:=""
      For _nI := 1 To _nTotLin
         _oModelZBD:GoLine( _nI )
         If _oModelZBD:IsDeleted()//igonora os deletados
            Loop
         EndIf
         _oModelZBD:LoadValue('ZBD_OPER'  , _cOperac)
         _oModelZBD:LoadValue('ZBD_ENTREG', _dDtEntreg)
         _oModelZBD:LoadValue('ZBD_PEDCLI', _cPedCom)
         _oModelZBD:LoadValue('ZBD_PEDCOM', _cPedCom)
         _oModelZBD:LoadValue('ZBD_CLIENT', _cCliente)
         _oModelZBD:LoadValue('ZBD_LOJACL', _cLoja)
         _oModelZBD:LoadValue('ZBD_CHAVE' , _cPedCom + _cCliente + _cLoja)
         If Empty(_cLocal1oItem)
            _cLocal1oItem:= _oModelZBD:GetValue('ZBD_LOCAL')
         EndIf
         _nPrcVend    := _oModelZBD:GetValue('ZBD_PRCVEN')
         _nQtd        := _oModelZBD:GetValue('ZBD_QTDVEN')
         _cCod        := _oModelZBD:GetValue('ZBD_PRODUT')

         If _nPrcVend == 0 .Or. _nQtd == 0 .Or. Empty(_cCod)
            Help( ,, 'Atenção'+" ["+DToC(Date())+"] ["+TIME()+"] AOMS132_011",, 'O Código de Produto, ou a Qantidade, ou o Preço Unitário de item não foi informado.', 1, 0 )
            _lRet := .F.
            Break
         EndIf

      Next _nI

      If _lRet
         //As variaveis de memoria M->C5_??????? são foram carregadas acima
         M->C5_I_LOCEM := U_BuscaLocalEmbarque(M->C5_FILGCT,_cLocal1oItem,M->C5_VEND1)//Função no Programa AOMS136.PRW
         If Empty(_cTabPrc)
            _aTabPrc := U_ITTABPRC(,,,,,,,.T.)//O Default dos parametros já pega tudo das vaiaveis de memoria (M->C5_???????) do SC5
            If Len(_aTabPrc) > 1
               _cTabPrc := _aTabPrc[1]
               _oModelZBC:LoadValue('ZBC_TABPRC', _cTabPrc)
               _oModelZBC:LoadValue('ZBC_DSCTBP', Posicione("DA0",1,xFilial("DA0")+_cTabPrc, "DA0_DESCRI"))
            EndIf
         EndIf
         _oModelZBC:LoadValue('ZBC_CHAVE', _cPedCom + _cCliente + _cLoja)
         _oModelZBC:LoadValue("ZBC_STATUS","P")//PENDENTE
         _oModelZBD:GoLine(1)
      EndIf

EndIf

End Sequence

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS132W
Autor-------------: Julio de Paula Paz
Data da Criacao---: 07/01/2022
Descrição---------: Função usada em dicionário de dados para permitir ou não a edição de campos. WHEN DO CAMPO ZBD_PRODUT
Parametros--------: _cCampo = Campo que chamou a Funão.
Retorno-----------: _lRet == .T. = Validação Ok.
                             .F. = não conformidade na validação.
===============================================================================================================================
*/
User Function AOMS132W(_cCampo) As logical
Return .T.

/*
===============================================================================================================================
Programa----------: AOMS132T
Autor-------------: Julio de Paula Paz
Data da Criacao---: 17/01/2022
Descrição---------: Lista os tipos de veiculos aceitos pelos clientes e suas respectivas quantidades de pallets.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS132T()

Local _nQtdPalete As numeric
Local _aDados     As array
Local _cSeek      As char

_cSeek:=ZBC->ZBC_CLIENT+ZBC->ZBC_LOJACL
DUT->(DBSetOrder(1)) // DUT_FILIAL+DUT_TIPVEI
ZBB->(DBSetOrder(1)) // ZBB_FILIAL+ZBB_CLIENT+ZBB_LOJA+ZBB_TPVEIC
If ! ZBB->(MsSeek(xFilial("ZBB")+_cSeek))
   U_ITMsg('Não existem tipos de veiculos cadastrados para este cliente '+_cSeek+' do pedido posicionado, será listados todos.',"Atenção",;
         'Acesse o cadastro de clientes, Posicione no cliente desejado e selecione a opção: "Clientes x Tipos Transportes" para cadastrar',3)
   _cSeek:=""
   ZBB->(MsSeek(xFilial("ZBB")+_cSeek))
EndIf

_aDados := {}
While ! ZBB->(Eof()) .And. ZBB->(ZBB_FILIAL+ZBB_CLIENT+ZBB_LOJA) = xFilial("ZBB")+_cSeek
   _nQtdPalete := 0
   If DUT->(MsSeek(xFilial("DUT")+ZBB->ZBB_TPVEIC))
      _nQtdPalete := DUT->DUT_QTUNIH//Alterar onde está utilizado o campo DUT_I_QPAL para DUT_QTUNIH (Qtd.Unitiz.Horizontal) chamado 37652
   EndIf

   aAdd(_aDados,{ZBB->ZBB_CLIENT,ZBB->ZBB_LOJA,ZBB->ZBB_NOMCLI,ZBB->ZBB_TPVEIC,ZBB->ZBB_NOMVEI,_nQtdPalete})
   ZBB->(DBSkip())
EndDo

If Len(_aDados) = 0
   U_ITMsg('Não existem tipos de veiculos cadastrados ainda para nenhum cliente.',"Atenção",'Acesse o cadastro de clientes, Posicione no cliente desejado e selecione a opção: "Clientes x Tipos Transportes"',1)
   Return .F.
Else
   _aTitulos := {"Cliente",;
            "Loja Cliente",;
            "Nome Cliente",;
            "Tipo Veiculo",;
            "Nome Veiculo",;
            "Qtde.Pallets"}

   U_ITListBox( 'Lista de Tipos de Veiculos para o Clinte' ,  _aTitulos , _aDados , .T. ,1)
EndIf

Return .F.

/*
===============================================================================================================================
Programa----------: AOMS132E
Autor-------------: Julio de Paula Paz
Data da Criacao---: 17/01/2022
Descrição---------: Efetiva o Pré-Pedido de Vendas. Ou Seja, gera o Pedido de Vendas no Protheus.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS132E()

Local _aSizeAut   As array
Local _lFinalizar As logical
Local _cNomeTipoV As char
Local _cVeiculo   As char
Local _cTipoAcao  As char
Local _nOpc       As numeric
Local _nLinha     As numeric
Local nI          As numeric
Local nUsado      As numeric
Local _aArea      AS array
Local _aAreaZBC   AS array
Local _aAreaZBD   AS array
Local _aAreaZBE   AS array
Local _aAreaZBF   AS array

Private aHeader      As array
Private aRotina      As array
Private _aDadosZBD   As array
Private _nTotPallet  As numeric
Private _nPaletVeic  As numeric
Private Altera       As logical
Private Inclui       As logical
Private _lJaGerouPV  As logical
Private _oTotPallet  As object
Private _oGetTRBF    As object
Private _OBtnEfetiva As object
Private _OBtnSair    As object
Private _cFilPedVe   As char
Private _cTRBZBF     As char
Private bGeraPVS     As CodeBlock

_nTotPallet:= 0
_nPaletVeic:= 0
aHeader    := {}
aRotina    := {}
Altera     := .T.
Inclui     := .F.
_lJaGerouPV:= .F.
_aSizeAut  := MsAdvSize(.T.)
_lFinalizar:= .F.
_nOpc      := 0
_aArea	    := FWGetArea()
_aAreaZBC  := ZBC->(GetArea())
_aAreaZBD  := ZBD->(GetArea())
_aAreaZBE  := ZBE->(GetArea())
_aAreaZBF  := ZBF->(GetArea())

Begin Sequence //Não retirar

ZBE->(DBSetOrder(2)) // ZBE_FILIAL+ZBE_PEDCOM+ZBE_CLIENT+ZBE_LOJACL
ZBF->(DBSetOrder(3))
If !ZBF->(MsSeek(xFilial("ZBF")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL))) .OR.;
   !ZBE->(MsSeek(xFilial("ZBE")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL)))
   U_ITMsg("Não existem Pre-Pedidos de Vendas Cadastrados para geração de pedidos de vendas no Protheus.","Atenção","",1)
   Break
EndIf

// Carrega os itens da tabela ZBD para validação de Quantidades
ZBD->(DBSetOrder(1))
ZBD->(MsSeek(xFilial("ZBD")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL)))

_aDadosZBD := {}
_nTotPallet:= 0

While ! ZBD->(Eof()) .And. ZBD->(ZBD_FILIAL+ZBD_PEDCOM+ZBD_CLIENT+ZBD_LOJACL) == xFilial("ZBD")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL)

   aAdd(_aDadosZBD, {ZBD->ZBD_ITEM                                ,;// Item
                     ZBD->ZBD_PRODUT                              ,;// Codigo do Produto
                     Trans(ZBD->ZBD_UNSVEN,"@E 999,999,999.9999") ,;// Qtd. Segunda Unidade Med.
                     ZBD->ZBD_SEGUM                               ,;// Segunda Unidade Medida
                     Trans(ZBD->ZBD_QTDVEN,"@E 999,999,999.9999") ,;// Qtd. Primeira Unidade Medida
                     ZBD->ZBD_UM                                  ,;// Primeira Unidade Medida
                     Trans(ZBD->ZBD_PRCVEN,"@E 999,999,999.99")   ,;// Preço Unitário Liquido
                     Trans(ZBD->ZBD_VALOR ,"@E 999,999,999.99")   ,;// Valor Total
                     Trans(ZBD->ZBD_QTDPAL,"@E 999,999,9999")     ,;// Quantidade de Paletes
                     ZBD->ZBD_DESCRI                              })// Descrição do Produto

   _nTotPallet += ZBD->ZBD_QTDPAL

   ZBD->(DBSkip())
EndDo


//=======================================================================
// Carrega os dados de capa para exibição da tela.
//=======================================================================
_nPaletVeic  := Posicione("DUT",1,xFilial("DUT")+ZBE->ZBE_TPVEIC,"DUT_QTUNIH")//Alterar onde está utilizado o campo DUT_I_QPAL para DUT_QTUNIH (Qtd.Unitiz.Horizontal) chamado 37652
_cNomeTipoV  := Posicione("DUT",1,xFilial("DUT")+ZBE->ZBE_TPVEIC,"DUT_DESCRI")
_cVeiculo    := ZBE->ZBE_TPVEIC + "-" + _cNomeTipoV

For nI := 1 To ZBC->(FCount())
      M->&(ZBC->(FIELDNAME(nI))) := ZBC->(FieldGet(nI))
Next nI
M->ZBC_TRCNF  := If(ZBC->ZBC_TRCNF=="S","Sim","Nao")

//===============================================================
// Work com a capa dos pré-pedidos de Vendas.
//===============================================================
_aStruct2 := FWSX3Util():GetListFieldsStruct( "ZBF" , .T.  )//Com campos virtuais

aAdd(_aStruct2, {"WK_PEDPROT", "C", 6,  0}) // Pedido de Vendas Protheus
aAdd(_aStruct2, {"WK_UNSVEN" , "N", 9 , 3}) // Qtd. Segunda Unidade Med.
aAdd(_aStruct2, {"WK_QTDVEN" , "N", 13, 3}) // Qtd. Primeira Unidade Medida
aAdd(_aStruct2, {"WK_RECNO"  , "N", 10, 0}) // Recno do Item ZBD
aAdd(_aStruct2, {"DELETED"   , "L" ,1  ,0})  // DELETE DO MSGETDB

_cTRBZBF:=GetNextAlias()

_oTemp2 := FWTemporaryTable():New(_cTRBZBF, _aStruct2 )
_oTemp2:AddIndex( "01", {"ZBF_PEDCOM", "ZBF_SEQ" , "ZBF_ITEM"} )// Para mostrar na tela
_oTemp2:AddIndex( "02", {"ZBF_PEDCOM", "ZBF_ITEM"} )//Para dar MsSeek na U_AOMS132O("TUDOOK_MANUT")
_oTemp2:Create()

//==============================================================================
// Grava os dados da tabela temporaria (_cTRBZBF)
//==============================================================================
ZBF->(DBSetOrder(3))
ZBF->(MsSeek(xFilial("ZBF")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL)))

While ! ZBF->(Eof()) .And. ZBF->(ZBF_FILIAL+ZBF_PEDCOM+ZBF_CLIENT+ZBF_LOJACL) == xFilial("ZBF")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL)

   (_cTRBZBF)->(DbAppend())
   For nI := 1 To ZBF->(FCount())
         (_cTRBZBF)->&(ZBF->(FIELDNAME(nI))) := ZBF->(FieldGet(nI))
   Next nI
   (_cTRBZBF)->WK_UNSVEN := ZBF->ZBF_UNSVEN   // Qtd. Segunda Unidade Med.
   (_cTRBZBF)->WK_QTDVEN := ZBF->ZBF_QTDVEN   // Qtd. Primeira Unidade Medida
   (_cTRBZBF)->WK_PEDPROT:= ZBF->ZBF_PVPROT   // Pedido de Vendas Protheus
   (_cTRBZBF)->WK_RECNO  := ZBF->(RECNO())    // Recno do Item ZBD

   If ! Empty(ZBF->ZBF_PVPROT)
      _lJaGerouPV := .T.
   EndIf

   ZBF->(DBSkip())
EndDo

// Monta aHeader do ms getdb.
aHeader:={}
_aSX3 := FWSX3Util():GetAllFields( "ZBF" ,  .F. )
For nUsado := 1 To Len(_aSX3)
   _cCampo:=_aSX3[nUsado]
   If _cCampo $ _cCpos_Nao_Usados
      Loop
   EndIf
   _cUsado:=GetSX3Cache(_cCampo,"X3_USADO")
   If X3USO(_cUsado)
                                                            //Estrutura do aHeader do MsNewGetDados      |
      aAdd( aHeader , {GetSX3Cache(_cCampo,"X3_TITULO")   ,;//aHeader[01] - X3_TITULO  | Título
                        GetSX3Cache(_cCampo,"X3_CAMPO")    ,;//aHeader[02] - X3_CAMPO   | Campo
                        GetSX3Cache(_cCampo,"X3_PICTURE")  ,;//aHeader[03] - X3_PICTURE | Picture
                        GetSX3Cache(_cCampo,"X3_TAMANHO")  ,;//aHeader[04] - X3_TAMANHO | Tamanho
                        GetSX3Cache(_cCampo,"X3_DECIMAL")  ,;//aHeader[05] - X3_DECIMAL | Decimal
                        GetSX3Cache(_cCampo,"X3_VALID")    ,;//aHeader[06] - X3_VALID   | Validação
                        _cUsado                            ,;//aHeader[07] - X3_USADO   | Usado
                        GetSX3Cache(_cCampo,"X3_TIPO")     ,;//aHeader[08] - X3_TIPO    | Tipo
                        GetSX3Cache(_cCampo,"X3_ARQUIVO")  ,;//aHeader[09] - X3_F3      | F3
                        GetSX3Cache(_cCampo,"X3_CONTEXT")  })//aHeader[10] - X3_CONTEXT | Contexto (R,V)
   EndIf
   If _cCampo = "ZBF_PVPROT
      aAdd(aHeader,{"Nr.Ped.Vendas Protheus"         ,;   //aHeader[01] - X3_TITULO  | Título
                     "WK_PEDPROT"                     ,;   //aHeader[02] - X3_CAMPO   | Campo
                     GetSX3Cache(_cCampo,"X3_PICTURE"),;   //aHeader[03] - X3_PICTURE | Picture
                     GetSX3Cache(_cCampo,"X3_TAMANHO"),;   //aHeader[04] - X3_TAMANHO | Tamanho
                     GetSX3Cache(_cCampo,"X3_DECIMAL"),;   //aHeader[05] - X3_DECIMAL | Decimal
                     GetSX3Cache(_cCampo,"X3_VALID")  ,;   //aHeader[06] - X3_VALID   | Validação
                     GetSX3Cache(_cCampo,"X3_USADO")  ,;   //aHeader[07] - X3_USADO   | Usado
                     GetSX3Cache(_cCampo,"X3_TIPO")   ,;   //aHeader[08] - X3_TIPO    | Tipo
                     GetSX3Cache(_cCampo,"X3_ARQUIVO"),;   //aHeader[09] - X3_F3      | F3
                     GetSX3Cache(_cCampo,"X3_CONTEXT")})   //aHeader[10] - X3_CONTEXT | Contexto (R,V)

   ElseIf _cCampo = "ZBF_UNSVEN
      aAdd(aHeader,{"Qtd.Atual.2 Un.Med."            ,;   //aHeader[01] - X3_TITULO  | Título
                     "WK_UNSVEN"                      ,;   //aHeader[02] - X3_CAMPO   | Campo
                     GetSX3Cache(_cCampo,"X3_PICTURE"),;   //aHeader[03] - X3_PICTURE | Picture
                     GetSX3Cache(_cCampo,"X3_TAMANHO"),;   //aHeader[04] - X3_TAMANHO | Tamanho
                     GetSX3Cache(_cCampo,"X3_DECIMAL"),;   //aHeader[05] - X3_DECIMAL | Decimal
                     GetSX3Cache(_cCampo,"X3_VALID")  ,;   //aHeader[06] - X3_VALID   | Validação
                     GetSX3Cache(_cCampo,"X3_USADO")  ,;   //aHeader[07] - X3_USADO   | Usado
                     GetSX3Cache(_cCampo,"X3_TIPO")   ,;   //aHeader[08] - X3_TIPO    | Tipo
                     GetSX3Cache(_cCampo,"X3_ARQUIVO"),;   //aHeader[09] - X3_F3      | F3
                     GetSX3Cache(_cCampo,"X3_CONTEXT")})   //aHeader[10] - X3_CONTEXT | Contexto (R,V)
   ElseIf _cCampo = "ZBF_QTDVEN"
      aAdd(aHeader,{"Qtd.Atual 1 Un Med"             ,;   //aHeader[01] - X3_TITULO  | Título
                     "WK_QTDVEN"                      ,;   //aHeader[02] - X3_CAMPO   | Campo
                     GetSX3Cache(_cCampo,"X3_PICTURE"),;   //aHeader[03] - X3_PICTURE | Picture
                     GetSX3Cache(_cCampo,"X3_TAMANHO"),;   //aHeader[04] - X3_TAMANHO | Tamanho
                     GetSX3Cache(_cCampo,"X3_DECIMAL"),;   //aHeader[05] - X3_DECIMAL | Decimal
                     GetSX3Cache(_cCampo,"X3_VALID")  ,;   //aHeader[06] - X3_VALID   | Validação
                     GetSX3Cache(_cCampo,"X3_USADO")  ,;   //aHeader[07] - X3_USADO   | Usado
                     GetSX3Cache(_cCampo,"X3_TIPO")   ,;   //aHeader[08] - X3_TIPO    | Tipo
                     GetSX3Cache(_cCampo,"X3_ARQUIVO"),;   //aHeader[09] - X3_F3      | F3
                     GetSX3Cache(_cCampo,"X3_CONTEXT")})   //aHeader[10] - X3_CONTEXT | Contexto (R,V)
   EndIf
Next nUsado


// Configurações iniciais
_aObjects := {}
aAdd( _aObjects, { 315,  50, .T., .T. } )
aAdd( _aObjects, { 100, 100, .T., .T. } )

_aInfo := { _aSizeAut[ 1 ], _aSizeAut[ 2 ], _aSizeAut[ 3 ], _aSizeAut[ 4 ], 3, 3 }

_aPosObj := MsObjSize( _aInfo, _aObjects, .T. )

aRotina := {}
aAdd(aRotina,{"","",0,2})
Inclui := .F.
Altera := .T.

_cTipoAcao := "Tela de Efetivação dos Pré-Pedido de Vendas"

If _lJaGerouPV
   _cTipoAcao := "Tela de Visualização dos Pedido de Vendas já Efetivados"
   //U_ITMsg("Pre-Pedidos de Vendas já efetivados.","Atenção","Será aberta a Tela para visualização.",3)
Else
   bGeraPVS:= {|| _lRet:=.F. ,  FWMsgRun(,{|oProc|  _lRet:=U_AOMS132P(oProc) },"AGUARDE...", "GERANDO PEDIDOS... ")   , _lRet  }
EndIf


While .T.

   _nOpc := 0
   _lFinalizar := .T.
   (_cTRBZBF)->(DBGoTop())

   DEFINE MSDIALOG _oDlgEfet TITLE _cTipoAcao FROM _aSizeAut[7],00 To _aSizeAut[6], _aSizeAut[5] PIXEL // 00,00 To 300,400

         _nLinha := 15
         @ _nLinha, 10 Say "Ped.Compras"	Pixel Size  030,012 Of _oDlgEfet
         @ _nLinha, 60 MSGet M->ZBC_PEDCOM  Pixel Size 040,012 WHEN .F. Of _oDlgEfet

         @ _nLinha, 115 Say "Tipo de Veiculo"	Pixel Size 040,012 Of _oDlgEfet
         @ _nLinha, 170 MSGet _cVeiculo  Pixel Size 130,012 WHEN .F. Of _oDlgEfet

         @ _nLinha, 406 Say "Total Pallets Veiculo:"	Pixel Size  080,012 Of _oDlgEfet
         @ _nLinha, 465 MSGet _nPaletVeic Pixel Size 040,012 WHEN .F. Of _oDlgEfet

         @ _nLinha, 520 Say "Total de Pallets do Pedido:"	Pixel Size  080,012 Of _oDlgEfet
         @ _nLinha, 590 MSGet _oTotPallet Var _nTotPallet Pixel Size 040,012 WHEN .F. Of _oDlgEfet

         _nLinha += 20
         @ _nLinha, 10 Say "Troca Nota"	Pixel Size 030,012 Of _oDlgEfet
         @ _nLinha, 60 MSGet M->ZBC_TRCNF Pixel Size 040,012 WHEN .F. Of _oDlgEfet

         @ _nLinha, 115 Say "Filial Faturamento"	Pixel Size 040,020 Of _oDlgEfet
         @ _nLinha, 170 MSGet M->ZBC_FLFNC Pixel Size 040,009 WHEN .F. Of _oDlgEfet

         @ _nLinha, 255 Say "Filial Carregamento"	Pixel Size 040,020 Of _oDlgEfet
         @ _nLinha, 305 MSGet M->ZBC_FILFT Pixel Size 100,012 WHEN .F. Of _oDlgEfet

         _nLinha += 20
         @ _nLinha, 10 Say "Cliente"	Pixel Size 030,012 Of _oDlgEfet
         @ _nLinha, 60 MSGet M->ZBC_CLIENT Pixel Size 040,012 WHEN .F. Of _oDlgEfet

         @ _nLinha, 115 Say "Loja Cliente"	Pixel Size 040, 012 Of _oDlgEfet
         @ _nLinha, 170 MSGet M->ZBC_LOJACL Pixel Size 040,009 WHEN .F. Of _oDlgEfet

         @ _nLinha, 255 Say "Nome Cliente"	Pixel Size 040,012 Of _oDlgEfet
         @ _nLinha, 305 MSGet M->ZBC_NOME Pixel Size 100,012 WHEN .F. Of _oDlgEfet

         _nLinha += 20

         @ _nLinha, 10 Say "Estado"	Pixel Size 030,012 Of _oDlgEfet
         @ _nLinha, 60 MSGet M->ZBC_EST Pixel Size 040,012 WHEN .F. Of _oDlgEfet

         @ _nLinha, 115 Say "Municipio"	Pixel Size 030,012 Of _oDlgEfet
         @ _nLinha, 170 MSGet M->ZBC_MUN Pixel Size 060,012 WHEN .F. Of _oDlgEfet

         @ _nLinha, 255 Say "CEP"	Pixel Size 030,012 Of _oDlgEfet
         @ _nLinha, 305 MSGet M->ZBC_CEP Pixel Size 040,012 WHEN .F. Of _oDlgEfet

         @ _nLinha, 375 Say "Bairro"	Pixel Size 030,012 Of _oDlgEfet
         @ _nLinha, 415 MSGet M->ZBC_BAIREN Pixel Size 080,012 WHEN .F. Of _oDlgEfet

         _nLinha += 20

         @ _nLinha, 10 Say "DDD"	Pixel Size 030,012 Of _oDlgEfet
         @ _nLinha, 60 MSGet M->ZBC_DDD Pixel Size 040,012 WHEN .F. Of _oDlgEfet

         @ _nLinha, 115 Say "Telefone"	Pixel Size 030,012 Of _oDlgEfet
         @ _nLinha, 170 MSGet M->ZBC_TELEFO Pixel Size 040,012 WHEN .F. Of _oDlgEfet

         @ _nLinha, 255 Say "Tp.Operação"	Pixel Size 040,012 Of _oDlgEfet
         @ _nLinha, 305 MSGet M->ZBC_OPERAC Pixel Size 040,012 WHEN .F. Of _oDlgEfet

         @ _nLinha, 375 Say "Tipo Pedido"	Pixel Size 040,012 Of _oDlgEfet
         @ _nLinha, 415 MSGet M->ZBC_TIPO Pixel Size 040,012 WHEN .F. Of _oDlgEfet

         @ _nLinha, 475 Say "Data Entrega"	Pixel Size 040,012 Of _oDlgEfet
         @ _nLinha, 515 MSGet M->ZBC_DTENT Pixel Size 040,012 WHEN .F. Of _oDlgEfet

         @ _nLinha, 570 Say "Vendedor"	Pixel Size 040,012 Of _oDlgEfet
         @ _nLinha, 605 MSGet M->ZBC_VEND1 Pixel Size 040,012 WHEN .F. Of _oDlgEfet
         _nLinha += 20

         // BOTÃO '4-Visualiza PVs Gerados / Efetiva Pre-PVs'    Action 'U_AOMS132E'

         // ZBF    //MsGetDB ():New(< nTop>, < nLeft>, < nBottom>       , < nRight>         ,< nOpc>, [ cLinhaOk], [ cTudoOk],[ cIniCpos], [ lDelete] , [ aAlter]      , [ nFreeze], [ lEmpty], [ uPar1], < cTRB>  , [ cFieldOk], [ uPar2], [ lAppend], [ oWnd] , [ lDisparos], [ uPar3], [ cDelOk], [ cSuperDel] ) --> oObj
         _oGetTRBF := MsGetDB():New(_nLinha, 0       , _aPosObj[2,3]-20 , _aPosObj[2,4]     , 1     ,            ,           , ""         , .F.       , {}             , 0         , .F.       ,        , _cTRBZBF ,            ,         , .F.       , _oDlgEfet, .T.) //         ,         ,""        , "")

         _oGetTRBF:oBrowse:bAdd := {||.F.} // não inclui novos itens MsGetDb ()
         _oGetTRBF:Enable( )

         _nColB:=5
         If !_lJaGerouPV
            @ _aPosObj[2,3]-15,_nColB BUTTON _OBtnEfetiva PROMPT "3-Efetivar Pré-Pedido" SIZE 70, 012 OF _oDlgEfet ACTION ( If(EVAL(bGeraPVS),( _lFinalizar := .F. ,_oDlgEfet:End()),)) PIXEL
            _nColB += 85
         EndIf
         @ _aPosObj[2,3]-15 , _nColB  BUTTON _OBtnSair    PROMPT "SAIR"                 SIZE 50, 012 OF _oDlgEfet ACTION ( ( _lFinalizar := .T. ,_oDlgEfet:End()) ) PIXEL

         (_cTRBZBF)->(DBGoTop())
         _oGetTRBF:ForceRefresh( )

   ACTIVATE MSDIALOG _oDlgEfet CENTERED

   If _lFinalizar
      Exit
   EndIf

EndDo

(_cTRBZBF)->(DBCloseArea())

End Sequence

FWRestArea(_aArea)
FWRestArea(_aAreaZBC)
FWRestArea(_aAreaZBD)
FWRestArea(_aAreaZBE)
FWRestArea(_aAreaZBF)

Return

/*
===============================================================================================================================
Programa----------: AOMS132Z
Autor-------------: Julio de Paula Paz
Data da Criacao---: 08/02/2022
Descrição---------: Valida a digitação dos pré-pedidos de Vendas.
Parametros--------: _cCampo = Campo que chamou a validação.
Retorno-----------: _lRet  = .T. = Campo validado.
                           = .F. = Campo não validado.
===============================================================================================================================
*/
User Function AOMS132Z(_cCampo As char) As logical
 
Local _lRet      As logical
Local _nI        As numeric
Local _aTitulos  As array
Local _aArea     AS array
Local _aAreaZBC  AS array
Local _aAreaZBD  AS array
Local _aAreaZBE  AS array
Local _aAreaZBF  AS array
_aArea	     := FWGetArea()
_aAreaZBC   := ZBC->(GetArea())
_aAreaZBD   := ZBD->(GetArea())
_aAreaZBE   := ZBE->(GetArea())
_aAreaZBF   := ZBF->(GetArea())
_lRet := .T.

If _cCampo == "VERITENS"
   _aTitulos:={"Item",;
               "Produto",;
               "Qtd.2UM",;
               "Seg.UM",;
               "Qtd.1UM",;
               "1UM",;
               "Prc.Unit.",;
               "Vlr.Total",;
               "Qtd.Paletes",;
               "Descricao do Produto"}
   U_ITListBox( 'Lista dos itens do Pedidos do Cliente.' ,  _aTitulos , _aDadosZBD , .F. ,1 ,"Total de Pallets: "+TRANS(_nTotPalZBD,"@E 999,999,999"))

ElseIf _cCampo == "TIPO_VEICULO"

   _nI := aScan(_aTipoVeic, _cTipoVeic)
   If _nI > 0
      _nPaletVeic  := _aDadosVeic[_nI,3]
      _cCodTpVeic  := _aDadosVeic[_nI,1]
   EndIf

ElseIf _cCampo == "GRAVAR"

   (_cTRBZBF)->(DBGoTop())
   If (_cTRBZBF)->(Eof()) .And. (_cTRBZBF)->(Bof())
      U_ITMsg("Não há dados para gravação do Pré-Pedido de Vendas.","Atenção","",1)
      _lRet := .F.
   EndIf

ElseIf _cCampo == "EXCLUIR_ZBE_ZBF"

   ZBF->(DBSetOrder(3)) // ZBF_FILIAL+ZBF_PEDCOM+ZBF_CLIENT+ZBF_LOJACL+ZBF_SEQ
   ZBE->(DBSetOrder(2)) // ZBE_FILIAL+ZBE_PEDCOM+ZBE_CLIENT+ZBE_LOJACL
   If !ZBF->(MsSeek(xFilial("ZBF")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL))) .AND.;
      !ZBE->(MsSeek(xFilial("ZBE")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL)))
      U_ITMsg("Não há dados gravados para excluir do Pré-Pedido de Vendas.","Atenção","Somente saia sem gravar.",1)
      _lRet := .F.
   EndIf

   If _lRet .And. !U_ITMsg("Confirma a exclusão dos Pré-Pedido de Vendas? (ZBE e ZBF)" ,"Atenção", ,3,2, 2)
      _lRet := .F.

   ElseIf _lRet

   While !ZBF->(Eof()) .And. ZBF->(ZBF_FILIAL+ZBF_PEDCOM+ZBF_CLIENT+ZBF_LOJACL) == xFilial("ZBF")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL)
         ZBF->(RecLock( "ZBF" , .F. ) )
      ZBF->(DBDelete())
      ZBF->(MSUnLock())
      ZBF->(DBSkip())
   EndDo

   ZBE->(MsSeek(xFilial("ZBE")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL)))
   While !ZBE->(Eof()) .And. ZBE->(ZBE_FILIAL+ZBE_PEDCOM+ZBE_CLIENT+ZBE_LOJACL) == xFilial("ZBE")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL)
         ZBE->(RecLock( "ZBE" , .F. ))
      ZBE->(DBDelete())
      ZBE->(MSUnLock())
      ZBE->(DBSkip())
   EndDo

   U_ITMsg("Exclusão concluida com sucesso. (ZBE e ZBF)","Atenção","",2)

   EndIf
EndIf

FWRestArea(_aArea)
FWRestArea(_aAreaZBC)
FWRestArea(_aAreaZBD)
FWRestArea(_aAreaZBE)
FWRestArea(_aAreaZBF)

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS132P
Autor-------------: Julio de Paula Paz
Data da Criacao---: 17/01/2022
Descrição---------: Efetiva um Pré-Pedido de vendas. Gera um novo Pedido de Vendas no Protheus(SC5 e SC6).
                    E abate os saldos dos pedido de compras do cliente principal.
Parametros--------: oProc
Retorno-----------: .T. ou .F.
===============================================================================================================================
*/
User Function AOMS132P(oProc As Ob) As Logical

Local _aItensPV   As array
Local _aItemPV    As array
Local _aCabPV     As array
Local _aAgrupaPV  As array
Local _aPVPorGrp  As array
Local _aPVPorSeq  As array
Local _aRecnoZBF  As array
Local _cSequen    As char
Local _cAgrupa    As char
Local _nI         As numeric
Local _cCodUsu    As Character
Local _lJob       As logical

Private _nColFilia As numeric
Private _nColAGEND As numeric
Private _nColDTENT As numeric
Private _nColTRCNF As numeric
Private _nColFLFNC As numeric
Private _nColFILFT As numeric
Private _nColOPER  As numeric
Private _nColCONPA As numeric
Private _nColSENHA As numeric
Private _nColOBPED As numeric
Private _nColMENNO As numeric
Private _nColDOCA  As numeric
Private _nColHOREN As numeric
Private _nConta    As numeric
Private _aRetGer   As array
Private _lGerouPV  As logical

_lGerouPV  := .T.
_aRetGer   := {}
_cFilAntBkp:= cFilAnt//SALVA A FILIAL ATUAL
_lJob       := IsBlind()

Begin Sequence //Não retirar

ZBF->(DBSetOrder(3))
ZBF->(MsSeek(ZBC->(ZBC_FILIAL+ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL)))

While ! ZBF->(Eof()) .And. ZBF->(ZBF_FILIAL+ZBF_PEDCOM+ZBF_CLIENT+ZBF_LOJACL) == ZBC->(ZBC_FILIAL+ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL)

   If !Empty(ZBF->ZBF_PVPROT)
      cLogErro:="Já existe o Pedido de Vendas [" + ZBF->ZBF_PVPROT+",...] gerado para este pedido de compras. Chave: "+ZBF->(ZBF_FILIAL+ZBF_PEDCOM+ZBF_CLIENT+ZBF_LOJACL)
      aAdd(_aRetGer,{.F.                    ,;
                     ZBF->ZBF_FILIAL        ,;
                     ZBF->ZBF_PEDCOM        ,;
                     ZBF->ZBF_AGRUPA        ,;
                     ZBF->ZBF_SEQ           ,;
                     ZBF->ZBF_AGENDA        ,;
                     ZBF->ZBF_DTENT         ,;
                     ZBF->ZBF_TRCNF         ,;
                     ZBF->ZBF_FLFNC         ,;
                     ZBF->ZBF_FILFT         ,;
                     cLogErro               })
      _lGerouPV := .F.
   EndIf

   ZBF->(DBSkip())
EndDo

If !_lGerouPV
   Break
EndIf

ZBE->(DBSetOrder(2))
ZBE->(MsSeek(ZBC->(ZBC_FILIAL+ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL)))

If !_lJob
   _cCodUsu	:= FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3]
Else
   _cCodUsu	:= "SISTEMA"
EndIf

//=================================================================
// Monta os arrays de inclusão de dados com MS EXECAUTO.
// Capa do Pedido de Vendas
//=================================================================
_aCabPV := {}
aAdd( _aCabPV, { "C5_FILIAL"   , ZBE->ZBE_FLFNC  , NiL})  // PODE/VAI SER TROCADA QUANDO TIVER LENDO O ZBF
_nColFilia:=Len(_aCabPV)
aAdd( _aCabPV, { "C5_CLIENTE"  , ZBE->ZBE_CLIENT , NiL})  // Cliente
aAdd( _aCabPV, { "C5_LOJACLI"  , ZBE->ZBE_LOJACL , NiL})  // Loja Cliente
aAdd( _aCabPV, { "C5_I_NOME"   , ZBE->ZBE_NOME   , NiL})  // Nome Cliente
aAdd( _aCabPV, { "C5_I_FANTA"  , ZBE->ZBE_FANTAS , NiL})  // Nom.Fantasia
aAdd( _aCabPV, { "C5_I_EST"    , ZBE->ZBE_EST    , NiL})  // Estado
aAdd( _aCabPV, { "C5_I_CMUN"   , ZBE->ZBE_CMUN   , NiL})  // Cod.Municipi
aAdd( _aCabPV, { "C5_I_MUN"    , ZBE->ZBE_MUN    , NiL})  // Municipio
aAdd( _aCabPV, { "C5_I_CEP"    , ZBE->ZBE_CEP    , NiL})  // CEP
aAdd( _aCabPV, { "C5_CLIENT"   , ZBE->ZBE_CLENTR , NiL})  // Clien.Entreg
aAdd( _aCabPV, { "C5_LOJAENT"  , ZBE->ZBE_LOJAEN , NiL})  // Loja Entrega
aAdd( _aCabPV, { "C5_I_END"    , ZBE->ZBE_ENDENT , NiL})  // End.Entrega
aAdd( _aCabPV, { "C5_I_BAIRR"  , ZBE->ZBE_BAIREN , NiL})  // Bairro
aAdd( _aCabPV, { "C5_I_DDD"    , ZBE->ZBE_DDD    , NiL})  // DDD
aAdd( _aCabPV, { "C5_I_TEL"    , ZBE->ZBE_TELEFO , NiL})  // Telefone
aAdd( _aCabPV, { "C5_I_OPER"   , ZBE->ZBE_OPERAC , NiL})  // Tp.Operação

_nColOPER:=Len(_aCabPV)
aAdd( _aCabPV, { "C5_TIPO"     , ZBE->ZBE_TIPO   , NiL})  // Tipo Pedido
aAdd( _aCabPV, { "C5_VEND1"    , ZBE->ZBE_VEND1  , NiL})  // Vendedor
aAdd( _aCabPV, { "C5_VEND2"    , ZBE->ZBE_VEND2  , NiL})  // Coordenador
aAdd( _aCabPV, { "C5_VEND3"    , ZBE->ZBE_VEND3  , NiL})  // Gerente
aAdd( _aCabPV, { "C5_VEND4"    , ZBE->ZBE_VEND4  , NiL})  // Supervisor
aAdd( _aCabPV, { "C5_I_TPVEN"  , ZBE->ZBE_TPVEN  , NiL})  // Tipo Venda INFORMAÇÃO DE CAPA mas vai ser controla por pedido de vendas pelo peso total
_nColTPVEN:=Len(_aCabPV)
aAdd( _aCabPV, { "C5_TPFRETE"  , ZBE->ZBE_TPFRET , NiL})  // Tipo Frete
aAdd( _aCabPV, { "C5_I_TAB"    , ZBE->ZBE_TABPRC , NiL})  // Tabela Preços

//Lista de Campos editaveis exeto os de quantidades: PROCURE #EDITAVEL para ver os campos que devem ser regravados, campos novos devem ser adicionados aqui e lá
aAdd( _aCabPV, { "C5_I_AGEND"  , ZBE->ZBE_AGENDA , NiL})  // PODE/VAI SER TROCADA QUANDO TIVER LENDO O ZBF - Tp Entrega
_nColAGEND:=Len(_aCabPV)
aAdd( _aCabPV, { "C5_I_DTENT"  , ZBE->ZBE_DTENT  , NiL})  // PODE/VAI SER TROCADA QUANDO TIVER LENDO O ZBF - Data Entrega
_nColDTENT:=Len(_aCabPV)
aAdd( _aCabPV, { "C5_I_TRCNF"  , ZBE->ZBE_TRCNF  , NiL})  // PODE/VAI SER TROCADA QUANDO TIVER LENDO O ZBF - Troca Nota
_nColTRCNF:=Len(_aCabPV)
aAdd( _aCabPV, { "C5_I_FLFNC"  , ZBE->ZBE_FLFNC  , NiL})  // PODE/VAI SER TROCADA QUANDO TIVER LENDO O ZBF - Filial Carregamento Troca Nota
_nColFLFNC:=Len(_aCabPV)
aAdd( _aCabPV, { "C5_I_FILFT"  , ZBE->ZBE_FILFT  , NiL})  // PODE/VAI SER TROCADA QUANDO TIVER LENDO O ZBF - Filial Faturamento Troca Nota
_nColFILFT:=Len(_aCabPV)
aAdd( _aCabPV, { "C5_CONDPAG"  , ZBE->ZBE_CONDPG , NiL})  // Cond.Pagto
_nColCONPA=Len(_aCabPV)
aAdd( _aCabPV, { "C5_I_SENHA"  , ZBE->ZBE_SENHA  , NiL})
_nColSENHA:=Len(_aCabPV)
aAdd( _aCabPV, { "C5_I_OBPED"  , ZBE->ZBE_OBPED  , NiL})
_nColOBPED:=Len(_aCabPV)
aAdd( _aCabPV, { "C5_MENNOTA"  , ZBE->ZBE_MENNOT , NiL})
_nColMENNO:=Len(_aCabPV)
aAdd( _aCabPV, { "C5_I_DOCA"   , ZBE->ZBE_DOCA   , NiL})
_nColDOCA:=Len(_aCabPV)
aAdd( _aCabPV, { "C5_I_HOREN"  , ZBE->ZBE_HOREN  , NiL})
_nColHOREN:=Len(_aCabPV)

aAdd( _aCabPV, { "C5_I_CDUSU"  , _cCodUsu        , NiL})  // Codigo Usuario

_aAgrupaPV := {}
_nPesoBrut := 0
ZBF->(DBSetOrder(3))
ZBF->(MsSeek(ZBC->(ZBC_FILIAL+ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL)))

While ! ZBF->(Eof()) .And. ZBE->(ZBE_FILIAL+ZBE_PEDCOM+ZBE_CLIENT+ZBE_LOJACL) == ZBF->(ZBF_FILIAL+ZBF_PEDCOM+ZBF_CLIENT+ZBF_LOJACL)

   aAdd(_aAgrupaPV,{ZBF->ZBF_FLFNC  ,;  // 1
                     ZBF->ZBF_AGRUPA ,;  // 2
                     ZBF->ZBF_SEQ    ,;  // 3
                     ZBF->ZBF_ITEM   ,;  // 4
                     ZBF->ZBF_PRODUT ,;  // 5
                     ZBF->(Recno())  })  // 6
   ZBF->(DBSkip())
EndDo
// Faz a ordenação do Array _aAgrupaPV para a geração dos Pedidos de vendas
aSort(_aAgrupaPV, , , { | x,y | x[1]+x[2]+x[3]+x[4]+x[5] < y[1]+y[2]+y[3]+y[4]+y[5] } )

_aPVPorGrp := {} // Array com agrupamento de pedidos de vendas.
_aPVPorSeq := {} // Array com separação de pedidos por sequencia.
SB1->(DBSetOrder(1))

For _nI := 1 To Len(_aAgrupaPV)

      If !Empty(_aAgrupaPV[_nI,2])
         aAdd(_aPVPorGrp, aClone(_aAgrupaPV[_nI]))  // Array com agrupamento de pedidos de vendas.
      EndIf

      If Empty(_aAgrupaPV[_nI,2])
         aAdd(_aPVPorSeq, aClone(_aAgrupaPV[_nI]))  // Array com separação de pedidos por sequencia.
      EndIf
Next _nI

_nConta   := 0 //CONTA QUANTOS PEDIDOS FOI GERADO
_nPVnaoGer:= 0 //CONTA QUANTOS PEDIDOS NÃO FOI GERADO

Begin Transaction  //*********** COMEÇA BEGIN TRANSACTION ***************//

// GERA OS PEDIDOS DE VENDAS COM POR GRUPO *************************************************************

If Len(_aPVPorGrp) > 0

   _cAgrupa  := _aPVPorGrp[1,1]+_aPVPorGrp[1,2]//QUEBRA POR FILIAL + GRUPO
   _cSequen  := _aPVPorGrp[1,3]//Só para passar como parametro
   _aItensPV := {}
   _aItemPV  := {}
   _aRecnoZBF:= {}

   For _nI := 1 To Len(_aPVPorGrp)

         If _cAgrupa  <> _aPVPorGrp[_nI,1]+_aPVPorGrp[_nI,2] .And. _nI > 1

            If !U_AOMS132F(_aCabPV, _aItensPV, _aRecnoZBF, _cAgrupa,_cSequen) // GERA PEDIDO DE VENDAS NO PROTHEUS. SC5 E SC6.
               _lGerouPV:=.F.
            EndIf
            _nPesoBrut:= 0 //ZERA O PESO BRUTO PARA O PROXIMO PEDIDO
            _cAgrupa  := _aPVPorGrp[_nI,1]+_aPVPorGrp[_nI,2] //QUEBRA POR FILIAL + GRUPO
            _cSequen  := _aPVPorGrp[_nI,3]//Só para passar como parametro
            _aRecnoZBF:= {}
            _aItensPV := {}
            _aItemPV  := {}
         EndIf

         ZBF->(DBGoTo(_aPVPorGrp[_nI, Len(_aPVPorGrp[_nI]) ])) // Posciona na tabela ZBF

         aAdd(_aRecnoZBF, ZBF->(Recno()))

         aAdd( _aItemPV , { "C6_FILIAL"   ,ZBF->ZBF_FLFNC   , Nil})  // Filial de carregamento sempre
         aAdd( _aItemPV , { "C6_ITEM"     ,ZBF->ZBF_ITEM    , Nil})  // Item
         aAdd( _aItemPV , { "C6_ITEMPC"   ,ZBF->ZBF_ITEM    , Nil})  // (grava C6_ITEM)
         aAdd( _aItemPV , { "C6_PRODUTO"  ,ZBF->ZBF_PRODUT  , Nil})  // Produto
         aAdd( _aItemPV , { "C6_DESCRI"   ,ZBF->ZBF_DESCRI  , Nil})  // Desc.Produto
         aAdd( _aItemPV , { "C6_UNSVEN"   ,ZBF->ZBF_UNSVEN  , Nil})  // Qtd.2.Um
         aAdd( _aItemPV , { "C6_SEGUM"    ,ZBF->ZBF_SEGUM   , Nil})  // Segunda Um
         aAdd( _aItemPV , { "C6_QTDVEN"   ,ZBF->ZBF_QTDVEN  , Nil})  // Qtd.1.Um
         aAdd( _aItemPV , { "C6_UM"       ,ZBF->ZBF_UM      , Nil})  // Primeira Um
         aAdd( _aItemPV , { "C6_PRCVEN"   ,ZBF->ZBF_PRCVEN  , Nil})  // Prc.Unitário
         aAdd( _aItemPV , { "C6_VALOR"    ,ZBF->ZBF_VALOR   , Nil})  // Vlr.Total
         aAdd( _aItemPV , { "C6_LOCAL"    ,ZBF->ZBF_LOCAL   , Nil})  // Armazem
         aAdd( _aItemPV , { "C6_ENTREG"   ,ZBF->ZBF_DTENT   , Nil})  // Dt.Entrega
         aAdd( _aItemPV , { "C6_PEDCLI"   ,ZBF->ZBF_PEDCLI  , Nil})  // Nr.Ped.Clien
         aAdd( _aItemPV , { "C6_NUMPCOM"  ,ZBF->ZBF_PEDCOM  , Nil})  // Ped.Compras
         aAdd( _aItemPV , { "C5_CLIENTE"  ,ZBF->ZBF_CLIENT  , Nil})  // Cliente
         aAdd( _aItemPV , { "C5_LOJACLI"  ,ZBF->ZBF_LOJACL  , Nil})  // Loja Cliente
         aAdd( _aItemPV , { "C6_I_QPALT"  ,ZBF->ZBF_QTDPAL  , Nil})  // Qtde.Paletes

         aAdd( _aItensPV ,_aItemPV )
         _aItemPV := {}

         //Lista de Campos editaveis exeto os de quantidades: PROCURE #EDITAVEL para ver os campos que devem ser regravados, campos novo devem ser adicionados aqui e nos outros #EDITAVEL
         //GRAVA OS DADOS DO ULTIMO PEDIDO DO GRUPO
         _aCabPV[_nColOPER ,2] := ZBF->ZBF_OPER  // C5_I_OPER  = ZBE->ZBE_OPERAC  // Tp.Operação
         _aCabPV[_nColFilia,2] := ZBF->ZBF_FLFNC // C5_I_FLFNC = ZBE->ZBE_FLFNC   // Filial Carregamento TROCA NOTA
         _aCabPV[_nColAGEND,2] := ZBF->ZBF_AGENDA// C5_I_AGEND = ZBE->ZBE_AGENDA  // Tp Entrega
         _aCabPV[_nColDTENT,2] := ZBF->ZBF_DTENT // C5_I_DTENT = ZBE->ZBE_DTENT   // Data Entrega
         _aCabPV[_nColTRCNF,2] := ZBF->ZBF_TRCNF // C5_I_TRCNF = ZBE->ZBE_TRCNF   // TROCA NOTA
         _aCabPV[_nColFLFNC,2] := ZBF->ZBF_FLFNC // C5_I_FLFNC = ZBE->ZBE_FLFNC   // Filial Carregamento TROCA NOTA
         _aCabPV[_nColFILFT,2] := ZBF->ZBF_FILFT // C5_I_FILFT = ZBE->ZBE_FILFT   // Filial Faturamento TROCA NOTA
         _aCabPV[_nColCONPA,2] := ZBF->ZBF_CONDPG// C5_CONDPAG = ZBE->ZBE_CONDPG  // Cond.Pagto
         _aCabPV[_nColSENHA,2] := ZBF->ZBF_SENHA // C5_I_SENHA = ZBE->ZBE_SENHA
         _aCabPV[_nColOBPED,2] := ZBF->ZBF_OBPED // C5_I_OBPED = ZBE->ZBE_OBPED
         _aCabPV[_nColMENNO,2] := ZBF->ZBF_MENNOT// C5_MENNOTA = ZBE->ZBE_MENNOT
         _aCabPV[_nColDOCA ,2] := ZBF->ZBF_DOCA  // C5_I_DOCA  = ZBE->ZBE_DOCA
         _aCabPV[_nColHOREN,2] := ZBF->ZBF_HOREN // C5_I_HOREN = ZBE->ZBE_HOREN

         If SB1->(DBSeek(xFilial("SB1")+ZBF->ZBF_PRODUT))
            _nPesoBrut+= SB1->B1_PESBRU * ZBF->ZBF_QTDVEN // Soma o peso bruto dos itens do pedido de compras
         EndIf

         If _nPesoBrut >= SuperGetMV("IT_PESOFEC",.F.,4000)
            _aCabPV[_nColTPVEN ,2] := "F" //F - Fechada
         Else
            _aCabPV[_nColTPVEN ,2] := "V" //V - Fracionada/Varejo
         EndIf   

   Next _nI

   If Len(_aItensPV) > 0
      If !U_AOMS132F(_aCabPV, _aItensPV, _aRecnoZBF, _cAgrupa,_cSequen) // Gera pedido de vendas no Protheus. SC5 e SC6.
         _lGerouPV:=.F.
      EndIf
   EndIf

EndIf

// GERA OS PEDIDOS DE VENDAS COM POR SEQUENCIA. *************************************************************

If Len(_aPVPorSeq) > 0

   _cSequen   := _aPVPorSeq[1,3]
   _aRecnoZBF := {}
   _aItensPV  := {}
   _aItemPV   := {}
   _nPesoBrut := 0

   For _nI := 1 To Len(_aPVPorSeq)

         If _cSequen  <> _aPVPorSeq[_nI,3] .And. _nI > 1

            If !U_AOMS132F(_aCabPV, _aItensPV, _aRecnoZBF, " ",_cSequen) // GERA PEDIDO DE VENDAS NO PROTHEUS. SC5 E SC6.
               _lGerouPV:=.F.
            EndIf

            _nPesoBrut:= 0 //ZERA O PESO BRUTO PARA O PROXIMO PEDIDO
            _cSequen  := _aPVPorSeq[_nI,3]
            _aRecnoZBF:= {}
            _aItensPV := {}
            _aItemPV  := {}
         EndIf

         ZBF->(DBGoTo(_aPVPorSeq[_nI, Len(_aPVPorSeq[_nI]) ])) // Posciona na tabela ZBF

         aAdd(_aRecnoZBF, ZBF->(Recno()))

         aAdd( _aItemPV , { "C6_FILIAL"   ,ZBF->ZBF_FLFNC   , Nil})  // Filial de carregamento sempre
         aAdd( _aItemPV , { "C6_ITEM"     ,ZBF->ZBF_ITEM    , Nil})  // Item
         aAdd( _aItemPV , { "C6_ITEMPC"   ,ZBF->ZBF_ITEM    , Nil})  // (grava C6_ITEM)
         aAdd( _aItemPV , { "C6_PRODUTO"  ,ZBF->ZBF_PRODUT  , Nil})  // Produto
         aAdd( _aItemPV , { "C6_DESCRI"   ,ZBF->ZBF_DESCRI  , Nil})  // Desc.Produto
         aAdd( _aItemPV , { "C6_UNSVEN"   ,ZBF->ZBF_UNSVEN  , Nil})  // Qtd.2.Um
         aAdd( _aItemPV , { "C6_SEGUM"    ,ZBF->ZBF_SEGUM   , Nil})  // Segunda Um
         aAdd( _aItemPV , { "C6_QTDVEN"   ,ZBF->ZBF_QTDVEN  , Nil})  // Qtd.1.Um
         aAdd( _aItemPV , { "C6_UM"       ,ZBF->ZBF_UM      , Nil})  // Primeira Um
         aAdd( _aItemPV , { "C6_PRCVEN"   ,ZBF->ZBF_PRCVEN  , Nil})  // Prc.Unitário
         aAdd( _aItemPV , { "C6_VALOR"    ,ZBF->ZBF_VALOR   , Nil})  // Vlr.Total
         aAdd( _aItemPV , { "C6_LOCAL"    ,ZBF->ZBF_LOCAL   , Nil})  // Armazem
         aAdd( _aItemPV , { "C6_ENTREG"   ,ZBF->ZBF_DTENT   , Nil})  // Dt.Entrega
         aAdd( _aItemPV , { "C6_PEDCLI"   ,ZBF->ZBF_PEDCLI  , Nil})  // Nr.Ped.Clien
         aAdd( _aItemPV , { "C6_NUMPCOM"  ,ZBF->ZBF_PEDCOM  , Nil})  // Ped.Compras
         aAdd( _aItemPV , { "C5_CLIENTE"  ,ZBF->ZBF_CLIENT  , Nil})  // Cliente
         aAdd( _aItemPV , { "C5_LOJACLI"  ,ZBF->ZBF_LOJACL  , Nil})  // Loja Cliente
         aAdd( _aItemPV , { "C6_I_QPALT"  ,ZBF->ZBF_QTDPAL  , Nil})  // Qtde.Paletes

         aAdd( _aItensPV ,_aItemPV )
         _aItemPV := {}


         //Lista de Campos editaveis exeto os de quantidades: PROCURE #EDITAVEL para ver os campos que devem ser regravados, campos novo devem ser adicionados aqui e nos outros #EDITAVEL
         //GRAVA OS DADOS DO ULTIMO PEDIDO DO GRUPO
         _aCabPV[_nColOPER ,2] := ZBF->ZBF_OPER  // C5_I_OPER  = ZBE->ZBE_OPERAC  // Tp.Operação
         _aCabPV[_nColFilia,2] := ZBF->ZBF_FLFNC // C5_I_FLFNC = ZBE->ZBE_FLFNC   // Filial Carregamento TROCA NOTA
         _aCabPV[_nColAGEND,2] := ZBF->ZBF_AGENDA// C5_I_AGEND = ZBE->ZBE_AGENDA  // Tp Entrega
         _aCabPV[_nColDTENT,2] := ZBF->ZBF_DTENT // C5_I_DTENT = ZBE->ZBE_DTENT   // Data Entrega
         _aCabPV[_nColTRCNF,2] := ZBF->ZBF_TRCNF // C5_I_TRCNF = ZBE->ZBE_TRCNF   // TROCA NOTA
         _aCabPV[_nColFLFNC,2] := ZBF->ZBF_FLFNC // C5_I_FLFNC = ZBE->ZBE_FLFNC   // Filial Carregamento TROCA NOTA
         _aCabPV[_nColFILFT,2] := ZBF->ZBF_FILFT // C5_I_FILFT = ZBE->ZBE_FILFT   // Filial Faturamento TROCA NOTA
         _aCabPV[_nColCONPA,2] := ZBF->ZBF_CONDPG// C5_CONDPAG = ZBE->ZBE_CONDPG  // Cond.Pagto
         _aCabPV[_nColSENHA,2] := ZBF->ZBF_SENHA // C5_I_SENHA = ZBE->ZBE_SENHA
         _aCabPV[_nColOBPED,2] := ZBF->ZBF_OBPED // C5_I_OBPED = ZBE->ZBE_OBPED
         _aCabPV[_nColMENNO,2] := ZBF->ZBF_MENNOT// C5_MENNOTA = ZBE->ZBE_MENNOT
         _aCabPV[_nColDOCA ,2] := ZBF->ZBF_DOCA  // C5_I_DOCA  = ZBE->ZBE_DOCA
         _aCabPV[_nColHOREN,2] := ZBF->ZBF_HOREN // C5_I_HOREN = ZBE->ZBE_HOREN

         If SB1->(DBSeek(xFilial("SB1")+ZBF->ZBF_PRODUT))
            _nPesoBrut+= SB1->B1_PESBRU * ZBF->ZBF_QTDVEN // Soma o peso bruto dos itens do pedido de compras
         EndIf

         If _nPesoBrut >= SuperGetMV("IT_PESOFEC",.F.,4000)
            _aCabPV[_nColTPVEN ,2] := "F" //F - Fechada
         Else
            _aCabPV[_nColTPVEN ,2] := "V" //V - Fracionada/Varejo
         EndIf   

   Next _nI

   If Len(_aItensPV) > 0

      If !U_AOMS132F(_aCabPV, _aItensPV, _aRecnoZBF, " ",_cSequen) // GERA PEDIDO DE VENDAS NO PROTHEUS. SC5 E SC6.
         _lGerouPV:=.F.
      EndIf
   EndIf

EndIf

If !_lGerouPV
   DisarmTransaction()
EndIf

End Transaction //*********** FIM DO BEGIN TRANSACTION ***************//

If !_lGerouPV
   For _nI := 1 To Len(_aRetGer)
         If _aRetGer[_nI,1] //Gerou
            _aRetGer[_nI,3] := ""
            _aRetGer[_nI,Len(_aRetGer[_nI])] := "Pedido de Vendas SERIA incluido com SUCESSO."
         EndIf
   Next _nI
   Break
   Else
   _lJaGerouPV:=.T.
   If Type("_OBtnEfetiva") == "O"
      _OBtnEfetiva:Disable()
   EndIf

   // Atualiza Work com os numeros dos Pedidos de Vendas Geredos.
   (_cTRBZBF)->(DBGoTop())
   While ! (_cTRBZBF)->(Eof())
      If !(_cTRBZBF)->DELETED .And. (_cTRBZBF)->WK_RECNO > 0
         ZBF->(DBGoTo((_cTRBZBF)->WK_RECNO))
         (_cTRBZBF)->WK_PEDPROT := ZBF->ZBF_PVPROT
      EndIf
      (_cTRBZBF)->(DBSkip())
   EndDo

   ZBC->(RecLock("ZBC",.F.))
   ZBC->ZBC_STATUS:= "F"
   ZBC->(MSUnLock())

EndIf

End Sequence

(_cTRBZBF)->(DBGoTop())
cFilAnt := _cFilAntBkp//VOLTA PARA FILIAL ATUAL

If Len(_aRetGer) > 0

_aTitulos:={""                                    ,;
            "Filial Gerada"                       ,;
            "Pedido Gerado"                       ,;
            "Fil+Grupo"                           ,;
            "Sequencia"                           ,;
            GetSX3Cache("ZBF_AGENDA","X3_TITULO") ,;
            GetSX3Cache("ZBF_DTENT ","X3_TITULO") ,;
            GetSX3Cache("ZBF_TRCNF ","X3_TITULO") ,;
            GetSX3Cache("ZBF_FLFNC ","X3_TITULO") ,;
            GetSX3Cache("ZBF_FILFT ","X3_TITULO") ,;
            "Resultados"}

U_ITListBox( 'Lista dos resultados dos Pedidos Gerados do Cliente'+ ZBC->ZBC_CLIENT+" "+ZBC->ZBC_LOJACL+" / PV: "+ZBC->ZBC_FILIAL+" "+ZBC->ZBC_PEDCOM,  _aTitulos , _aRetGer , .T. , 4 , )

EndIf

Return _lGerouPV

/*
===============================================================================================================================
Programa----------: AOMS132I
Autor-------------: Julio de Paula Paz
Data da Criacao---: 14/03/2022
Descrição---------: Gera o Pré-Pedido de Vendas com base na quantidade de Pallets o Pedido de compras do Cliente.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS132I()
Local _cTexto     As char
Local _cSeqPed    As char
Local _aStruct    As array
Local _aSizeAut   As array
Local _bGerPrePd  As block
Local _nQtd       As numeric
Local _nQtd2Un    As numeric
Local _nLinha     As numeric
Local nUsado      As numeric
Local nI          As numeric
Local _aArea      AS array
Local _aAreaZBC   AS array
Local _aAreaZBD   AS array
Local _aAreaZBE   AS array
Local _aAreaZBF   AS array

Private _cTipoVeic  As char
Private _cCodTpVeic As char
Private _aTipoVeic  As array
Private _aDadosVeic As array
Private aHeader     As array
Private aRotina     As array
Private _aDadosZBD  As array
Private _nTotPalZBD As numeric
Private _nTotPallet As numeric
Private _nPaletVeic As numeric
Private _nQtdPalet  As numeric
Private _oBtnGerPr  As object
Private _oTipoVeic  As object
Private _oGetDBF    As object
Private _OBtnGrava  As object
Private _OBtnSair   As object
Private _lBtnGerPr  As logical
Private _lTipoVeic  As logical
Private Altera      As logical
Private Inclui      As logical
Private _nOpc       As numeric
Private _cTRBZBD    As char
Private _cTRBZBF    As char

_cTRBZBD    := ""
_cTRBZBF    := ""
_cTipoVeic  := ""
_cCodTpVeic := ""
_aTipoVeic  := {}
_aDadosVeic := {}
aHeader     := {}
aRotina     := {}
_aDadosZBD  := {}
_nTotPalZBD := 0
_nTotPallet := 0
_nPaletVeic := 0
Altera      := .T.
Inclui      := .F.
_aSizeAut   := MsAdvSize(.T.)
_nOpc       := 0
_aArea	    := FWGetArea()
_aAreaZBC   := ZBC->(GetArea())
_aAreaZBD   := ZBD->(GetArea())
_aAreaZBE   := ZBE->(GetArea())
_aAreaZBF   := ZBF->(GetArea())

Begin Sequence //Não retirar

   ZBE->(DBSetOrder(2)) // ZBE_FILIAL+ZBE_PEDCOM+ZBE_CLIENT+ZBE_LOJACL
   If ZBE->(MsSeek(xFilial("ZBE")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL)))
      U_ITMsg("Já existe Pre-Pedido de Vendas Cadastrado para este pedido de compras.",'Atenção','Acesse a opção "Manutenção Pre-Pedidos Vendas" para alterar-lo.',3)
      Break
   EndIf

   ZBB->(DBSetOrder(1)) // ZBB_FILIAL+ZBB_CLIENT+ZBB_LOJA+ZBB_TPVEIC
   If ! ZBB->(MsSeek(xFilial("ZBB")+ZBC->ZBC_CLIENT+ZBC->ZBC_LOJACL))
      U_ITMsg("Não existem tipos de veiculos cadastrados para este cliente!","Atenção","Cadastre os tipos de veiculos aceitados por este cliente.",1)
      Break
   EndIf

   While ! ZBB->(Eof()) .And. ZBB->(ZBB_FILIAL+ZBB_CLIENT+ZBB_LOJA) == xFilial("ZBB")+ZBC->ZBC_CLIENT+ZBC->ZBC_LOJACL
      _nQtdPalet := Posicione("DUT",1,xFilial("DUT")+ZBB->ZBB_TPVEIC,"DUT_QTUNIH")//Alterar onde está utilizado o campo DUT_I_QPAL para DUT_QTUNIH (Qtd.Unitiz.Horizontal) chamado 37652
      _cTexto := AllTrim(ZBB->ZBB_NOMVEI) + "-[" + StrZero(_nQtdPalet,3)+"]-PALETES"
      aAdd(_aTipoVeic, _cTexto)
      aAdd(_aDadosVeic, {ZBB->ZBB_TPVEIC, ZBB->ZBB_NOMVEI,_nQtdPalet})

      ZBB->(DBSkip())
   EndDo

   For nI := 1 To ZBC->(FCount())
      M->&(ZBC->(FIELDNAME(nI))) := ZBC->(FieldGet(nI))
   Next nI
   M->ZBC_TRCNF  := If(ZBC->ZBC_TRCNF=="S","Sim","Nao")
   M->ZBC_AGENDA := U_TipoEntrega(ZBC->ZBC_AGENDA)

   _aStruct := {}
   aAdd(_aStruct, {"ZBD_ITEM"  , "C", 2 , 0}) // Item
   aAdd(_aStruct, {"ZBD_PRODUT", "C", 15, 0}) // Codigo do Produto
   aAdd(_aStruct, {"ZBD_DESCRI", "C", 50, 0}) // Descrição do Produto
   aAdd(_aStruct, {"ZBD_UNSVEN", "N", 9 , 3}) // Qtd. Segunda Unidade Med.
   aAdd(_aStruct, {"WK_UNSVEN" , "N", 9 , 3}) // Qtd. Segunda Unidade Med.
   aAdd(_aStruct, {"ZBD_SEGUM" , "C", 2 , 0}) // Segunda Unidade Medida
   aAdd(_aStruct, {"ZBD_QTDVEN", "N", 13, 3}) // Qtd. Primeira Unidade Medida
   aAdd(_aStruct, {"WK_QTDVEN" , "N", 13, 3}) // Qtd. Primeira Unidade Medida
   aAdd(_aStruct, {"ZBD_UM"    , "C", 2 , 0}) // Primeira Unidade Medida
   aAdd(_aStruct, {"ZBD_PRCVEN", "N", 18, 8}) // Preço Unitário Liquido
   aAdd(_aStruct, {"ZBD_VALOR" , "N", 12, 2}) // Valor Total
   aAdd(_aStruct, {"ZBD_LOCAL" , "C", 2 , 0}) // Armazém
   aAdd(_aStruct, {"ZBD_QTDPAL", "N", 3 , 0}) // Quantidade de Paletes
   aAdd(_aStruct, {"WK_QTDPAL" , "N", 3 , 0}) // Quantidade de Paletes
   aAdd(_aStruct, {"WK_CXPALET", "N",  4, 0}) // Quantidades por Palete
   aAdd(_aStruct, {"WK_QTDPPAL", "N", 13, 3}) // Quantidade de Paletes
   aAdd(_aStruct, {"WK_RECNO"  , "N", 10, 0}) // RECNO DO ZBD

   _cTRBZBD:=GetNextAlias()
   _oTemp := FWTemporaryTable():New(_cTRBZBD, _aStruct )
   _oTemp:AddIndex( "01", {"ZBD_ITEM","ZBD_PRODUT"} )

   _oTemp:Create()

   //===============================================================
   // Work com a capa dos pré-pedidos de Vendas.
   //===============================================================
   _aStruct2 := {}
   aAdd(_aStruct2, {"ZBF_PEDCOM", "C", 20, 0}) // Pedido de Compras
   aAdd(_aStruct2, {"ZBF_SEQ"   , "C", 3 , 0}) // Sequencia
   aAdd(_aStruct2, {"ZBF_ITEM"  , "C", 2 , 0}) // Item
   aAdd(_aStruct2, {"ZBF_PRODUT", "C", 15, 0}) // Codigo do Produto
   aAdd(_aStruct2, {"ZBF_DESCRI", "C", 50, 0}) // Descrição do Produto
   aAdd(_aStruct2, {"ZBF_UNSVEN", "N", 9 , 3}) // Qtd. Segunda Unidade Med.
   aAdd(_aStruct2, {"WK_UNSVEN" , "N", 9 , 3}) // Qtd. Segunda Unidade Med.
   aAdd(_aStruct2, {"ZBF_SEGUM" , "C", 2 , 0}) // Segunda Unidade Medida
   aAdd(_aStruct2, {"ZBF_QTDVEN", "N", 13, 3}) // Qtd. Primeira Unidade Medida
   aAdd(_aStruct2, {"WK_QTDVEN" , "N", 13, 3}) // Qtd. Primeira Unidade Medida
   aAdd(_aStruct2, {"ZBF_UM"    , "C", 2 , 0}) // Primeira Unidade Medida
   aAdd(_aStruct2, {"ZBF_PRCVEN", "N", 18, 8}) // Preço Unitário Liquido
   aAdd(_aStruct2, {"ZBF_VALOR" , "N", 12, 2}) // Valor Total
   aAdd(_aStruct2, {"ZBF_LOCAL" , "C", 2 , 0}) // Armazém
   aAdd(_aStruct2, {"ZBF_QTDPAL", "N", 3 , 0}) // Quantidade de Paletes
   aAdd(_aStruct2, {"WK_QTDPAL" , "N", 3 , 0}) // Quantidade de Paletes
   aAdd(_aStruct2, {"WK_QTDPPAL", "N", 13, 3}) // Quantidade por Paletes
   aAdd(_aStruct2, {"WK_RECNO"  , "N", 10, 0}) // Recno ZBF 
   aAdd(_aStruct2, {"DELETED"   , "L" ,1  ,0}) // DELETE DO MSGETDB

   _cTRBZBF:=GetNextAlias()
   _oTemp2 := FWTemporaryTable():New(_cTRBZBF, _aStruct2 )
   _oTemp2:AddIndex( "01", {"ZBF_PEDCOM", "ZBF_SEQ", "ZBF_ITEM"} )
   _oTemp2:AddIndex( "02", {"ZBF_PEDCOM", "ZBF_ITEM"} )//Para dar MsSeek na U_AOMS132O("TUDOOK_MANUT")
   _oTemp2:Create()

   // Grava work trb e array do ZBD .
   SB1->(DBSetOrder(1))
   ZBD->(DBSetOrder(1))	// ZBD_FILIAL+ZBD_PEDCOM+ZBD_CLIENT+ZBD_LOJACL+ZBD_PRODUT+ZBD_ITEM
   ZBD->(MsSeek(ZBC->(ZBC_FILIAL+ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL)))
   While ! ZBD->(Eof()) .And. ZBC->(ZBC_FILIAL+ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL) == ZBD->(ZBD_FILIAL+ZBD_PEDCOM+ZBD_CLIENT+ZBD_LOJACL)

      _nQtd    := ZBD->ZBD_QTDVEN
      _nQtd2Un := ZBD->ZBD_UNSVEN

      SB1->(MsSeek(xFilial("SB1")+ZBD->ZBD_PRODUT))

      (_cTRBZBD)->(DbAppend())
      For nI := 1 To ZBD->(FCount())
         (_cTRBZBD)->&(ZBD->(FIELDNAME(nI))) := ZBD->(FieldGet(nI))
      Next nI
      (_cTRBZBD)->ZBD_VALOR    := (ZBD->ZBD_PRCVEN * ZBD->ZBD_QTDVEN)  // Valor Total
      (_cTRBZBD)->WK_RECNO     := ZBD->(Recno())        // Recno da tabela ZBD
      (_cTRBZBD)->WK_QTDPPAL   := SB1->B1_I_CXPAL       // Quantidades por Palete.
      (_cTRBZBD)->WK_QTDPAL    := (_cTRBZBD)->ZBD_QTDPAL// Quantidade de Paletes
      (_cTRBZBD)->WK_CXPALET   := SB1->B1_I_CXPAL       // Quantidades por Palete
      _nTotPallet += (_cTRBZBD)->ZBD_QTDPAL

      aAdd(_aDadosZBD, {ZBD->ZBD_ITEM                               ,;// Item
                        ZBD->ZBD_PRODUT                             ,;// Codigo do Produto
                        Trans(ZBD->ZBD_UNSVEN,"@E 999,999,999.9999"),;// Qtd. Segunda Unidade Med.
                        ZBD->ZBD_SEGUM                              ,;// Segunda Unidade Medida
                        Trans(ZBD->ZBD_QTDVEN,"@E 999,999,999.9999"),;// Qtd. Primeira Unidade Medida
                        ZBD->ZBD_UM                                 ,;// Primeira Unidade Medida
                        Trans(ZBD->ZBD_PRCVEN,"@E 999,999,999.99")  ,;// Preço Unitário Liquido
                        Trans(ZBD->ZBD_VALOR ,"@E 999,999,999.99")  ,;// Valor Total
                        Trans(ZBD->ZBD_QTDPAL,"@E 999,999,9999")    ,;// Quantidade de Paletes
                        ZBD->ZBD_DESCRI                             })// Descrição do Produto

      _nTotPalZBD += ZBD->ZBD_QTDPAL

      ZBD->(DBSkip())
   EndDo

   aHeader:={}
   _aSX3 := FWSX3Util():GetAllFields( "ZBF" ,  .F. )
   For nUsado := 1 To Len(_aSX3)
      _cCampo:=_aSX3[nUsado]
      If _cCampo $ _cCpos_Nao_Usados
         Loop
      EndIf
      _cUsado:=GetSX3Cache(_cCampo,"X3_USADO")
      If X3USO(_cUsado)
         aAdd( aHeader , {GetSX3Cache(_cCampo,"X3_TITULO")  ,;
                        GetSX3Cache(_cCampo,"X3_CAMPO")   ,;
                        GetSX3Cache(_cCampo,"X3_PICTURE") ,;
                        GetSX3Cache(_cCampo,"X3_TAMANHO") ,;
                        GetSX3Cache(_cCampo,"X3_DECIMAL") ,;
                        GetSX3Cache(_cCampo,"X3_VALID")   ,;
                        _cUsado                           ,;
                        GetSX3Cache(_cCampo,"X3_TIPO")    ,;
                        GetSX3Cache(_cCampo,"X3_ARQUIVO") ,;
                        GetSX3Cache(_cCampo,"X3_CONTEXT") })
      EndIf
   Next nUsado

   _aObjects := {}
   aAdd( _aObjects, { 315,  50, .T., .T. } )
   aAdd( _aObjects, { 100, 100, .T., .T. } )

   _aInfo := { _aSizeAut[ 1 ], _aSizeAut[ 2 ], _aSizeAut[ 3 ], _aSizeAut[ 4 ], 3, 3 }

   _aPosObj := MsObjSize( _aInfo, _aObjects, .T. )

   aRotina := {}
   aAdd(aRotina,{"","",0,4})
   Inclui := .F.
   Altera := .T.

   _cTipoVeic  := _aTipoVeic[1]
   _nPaletVeic := _aDadosVeic[1,3]
   _cCodTpVeic := _aDadosVeic[1,1]

   _bGerPrePd := {|| Processa( {|| U_AOMS132D() ,_nOpc := 2 , _oDlgPre:End()} , 'Aguarde!' , 'Gerando Pré-Pedido de Vendas...' )}
   _lBtnGerPr := .F.
   _lTipoVeic := .F.

   While .T.
      _nOpc := 0
      (_cTRBZBD)->(DBGoTop())

      DEFINE MSDIALOG _oDlgPre TITLE "Geração dos Pré-Pedidos de Vendas" FROM _aSizeAut[7],00 To _aSizeAut[6], _aSizeAut[5] PIXEL

         _nLinha := 15
         @ _nLinha+1, 10 Say "Ped.Compras"	Pixel Size  030,012 Of _oDlgPre
         @ _nLinha, 60 MSGet M->ZBC_PEDCOM  Pixel Size 040,012 WHEN .F. Of _oDlgPre

         @ _nLinha+1, 115 Say "Tipo de Veiculo"	Pixel Size 040,012 Of _oDlgPre
         @ _nLinha, 170 MSCOMBOBOX _oTipoVeic Var _cTipoVeic ITEMS _aTipoVeic Valid(U_AOMS132Z("TIPO_VEICULO")) Pixel Size 160, 012 Of _oDlgPre

         @ _nLinha+1, 350 Say "Total Pallets Veiculo:"	Pixel Size  080,012 Of _oDlgPre
         @ _nLinha, 415 MSGet _nPaletVeic Pixel Size 040,012 WHEN .F. Of _oDlgPre

         @ _nLinha+1, 470 Say "Total de Pallets do Pedido:"	Pixel Size  080,012 Of _oDlgPre
         @ _nLinha, 540 MSGet _oTotPallet Var _nTotPallet Pixel Size 040,012 WHEN .F. Of _oDlgPre

         _nLinha += 20
         @ _nLinha+1, 10 Say "Troca Nota"	Pixel Size 030,012 Of _oDlgPre
         @ _nLinha, 60 MSGet M->ZBC_TRCNF Pixel Size 040,012 WHEN .F. Of _oDlgPre

         @ _nLinha+1, 115 Say "Filial Faturamento"	Pixel Size 040, 020 Of _oDlgPre
         @ _nLinha, 170 MSGet M->ZBC_FLFNC Pixel Size 040,009 WHEN .F. Of _oDlgPre

         @ _nLinha+1, 255 Say "Filial Carregamento"	Pixel Size 040,020 Of _oDlgPre
         @ _nLinha, 305 MSGet M->ZBC_FILFT Pixel Size 100,012 WHEN .F. Of _oDlgPre

         @ _nLinha+1, 415 Say "Tipo Pedido"	Pixel Size 040,012 Of _oDlgPre
         @ _nLinha, 470 MSGet M->ZBC_TIPO Pixel Size 040,012 WHEN .F. Of _oDlgPre

         _nLinha += 20
         @ _nLinha+1, 10 Say "Cliente"	Pixel Size 030,012 Of _oDlgPre
         @ _nLinha, 60 MSGet M->ZBC_CLIENT Pixel Size 040,012 WHEN .F. Of _oDlgPre

         @ _nLinha+1, 115 Say "Loja Cliente"	Pixel Size 040, 012 Of _oDlgPre
         @ _nLinha, 170 MSGet M->ZBC_LOJACL Pixel Size 040,009 WHEN .F. Of _oDlgPre

         @ _nLinha+1, 255 Say "Nome Cliente"	Pixel Size 040,012 Of _oDlgPre
         @ _nLinha, 305 MSGet M->ZBC_NOME Pixel Size 100,012 WHEN .F. Of _oDlgPre

         _nLinha += 20

         @ _nLinha+1, 10 Say "Estado"	Pixel Size 030,012 Of _oDlgPre
         @ _nLinha, 60 MSGet M->ZBC_EST Pixel Size 040,012 WHEN .F. Of _oDlgPre

         @ _nLinha+1, 115 Say "Municipio"	Pixel Size 030,012 Of _oDlgPre
         @ _nLinha, 170 MSGet M->ZBC_MUN Pixel Size 060,012 WHEN .F. Of _oDlgPre

         @ _nLinha+1, 255 Say "CEP"	Pixel Size 030,012 Of _oDlgPre
         @ _nLinha, 305 MSGet M->ZBC_CEP Pixel Size 040,012 WHEN .F. Of _oDlgPre

         @ _nLinha+1, 355 Say "Bairro"	Pixel Size 030,012 Of _oDlgPre
         @ _nLinha, 400 MSGet M->ZBC_BAIREN Pixel Size 080,012 WHEN .F. Of _oDlgPre

         _nLinha += 20

         @ _nLinha+1, 10 Say "DDD"	             Pixel Size 030,012 Of _oDlgPre
         @ _nLinha, 60 MSGet M->ZBC_DDD         Pixel Size 040,012 Of _oDlgPre WHEN .F.

         @ _nLinha+1, 115 Say "Telefone"	     Pixel Size 030,012 Of _oDlgPre
         @ _nLinha, 170 MSGet M->ZBC_TELEFO     Pixel Size 040,012 Of _oDlgPre WHEN .F.

         @ _nLinha+1, 255 Say "Tp.Operação"	 Pixel Size 040,012 Of _oDlgPre
         @ _nLinha, 305 MSGet M->ZBC_OPERAC     Pixel Size 040,012 Of _oDlgPre WHEN .F.

         @ _nLinha+1,355 Say "Tipo Agendamento" Pixel Size 040,012 Of _oDlgPre
         @ _nLinha, 400 MSGet M->ZBC_AGENDA     Pixel Size 075,012 Of _oDlgPre WHEN .F.

         @ _nLinha+1, 490 Say "Data Entrega"    Pixel Size 040,012 Of _oDlgPre
         @ _nLinha, 525 MSGet M->ZBC_DTENT      Pixel Size 040,012 Of _oDlgPre WHEN .F.

         @ _nLinha+1, 575 Say "Vendedor"	     Pixel Size 040,012 Of _oDlgPre
         @ _nLinha, 605 MSGet M->ZBC_VEND1      Pixel Size 040,012 Of _oDlgPre WHEN .F.
         _nLinha += 20
         
         // BOTÃO '2-Gerar Pre-Pedidos Vendas' Action 'U_AOMS132I'
         
         //    /////MsGetDB ():New(< nTop>, < nLeft>, < nBottom>       , < nRight>         ,< nOpc>, [ cLinhaOk], [ cTudoOk],[ cIniCpos], [ lDelete] , [ aAlter]      , [ nFreeze], [ lEmpty], [ uPar1], < cTRB>  , [ cFieldOk], [ uPar2], [ lAppend], [ oWnd] , [ lDisparos], [ uPar3], [ cDelOk], [ cSuperDel] ) --> oObj
         _oGetDBF := MsGetDB():New(_nLinha, 0       , _aPosObj[2,3]-20 , _aPosObj[2,4]     , 1     ,            ,           , ""         , .F.       , {}             , 0         , .F.       ,        , _cTRBZBF ,            ,         , .F.       , _oDlgPre, .F.) //         ,         ,""        , "")

         _oGetDBF:oBrowse:bAdd := {||.F.} // não inclui novos itens MsGetDb ()
         _oGetDBF:Enable( )

         @ _aPosObj[2,3]-15, 005 BUTTON _oBtnGerPr PROMPT "2-Gerar Pre-Pedidos Vendas" SIZE 100, 012 OF _oDlgPre ACTION ( Eval(_bGerPrePd) )         PIXEL // AOMS132D(
         @ _aPosObj[2,3]-15, 115 BUTTON _OBtnGrava PROMPT "Gravar"                     SIZE 070, 012 OF _oDlgPre ACTION ( If(U_AOMS132Z("GRAVAR"),(_nOpc := 1 ,_oDlgPre:End()),)) PIXEL
         @ _aPosObj[2,3]-15, 200 BUTTON _OBtnGrava PROMPT "Ver Itens"                  SIZE 070, 012 OF _oDlgPre ACTION ( U_AOMS132Z("VERITENS"))    PIXEL
         @ _aPosObj[2,3]-15, 285 BUTTON _OBtnSair  PROMPT "SAIR"	                      SIZE 050, 012 OF _oDlgPre ACTION ( (_nOpc:=0,_oDlgPre:End())) PIXEL

         If _lBtnGerPr
            _oBtnGerPr:Disable()
         EndIf

         If _lTipoVeic
            _oTipoVeic:Disable()
         EndIf

         (_cTRBZBD)->(DBGoTop())
         _oGetDBF:ForceRefresh( )

      ACTIVATE MSDIALOG _oDlgPre CENTERED

      If _nOpc = 0
         If U_ITMsg("Confirma SAIR da geração do Pré-Pedido de Vendas?" ,"Atenção","TODAS AS ALTERÇÕES SERÃO PERDIDAS." ,3,2, 2)
            Exit
         EndIf
      EndIf

      If _nOpc == 1
         If U_ITMsg("Confirma a Gravação dos Pré-Pedidos de Vendas?" ,"Atenção", ,3,2, 2)
            Exit
         EndIf
      EndIf

   EndDo

   If _nOpc == 1

      Begin Transaction
         (_cTRBZBF)->(DBGoTop())

         _cSeqPed := Space(3)

         While ! (_cTRBZBF)->(Eof())
            If (_cTRBZBF)->DELETED
               (_cTRBZBF)->(DBSkip())
               Loop
            EndIf

            If _cSeqPed <> (_cTRBZBF)->ZBF_SEQ

               ZBE->(RecLock("ZBE",.T.))
               For nI := 1 To ZBC->(FCount())
                  _cCampo:=StrTran(ZBC->(FIELDNAME(nI)),"ZBC_","ZBE_")//GRAVA ZBC NO ZBE
                  ZBE->&(_cCampo) := ZBC->(FieldGet(nI))
               Next nI
               ZBE->ZBE_SEQ      := (_cTRBZBF)->ZBF_SEQ
               ZBE->ZBE_TPVEIC   := _cCodTpVeic        // Codigo do Tipo de Veiculo
               ZBE->(MSUnLock())

               _cSeqPed := (_cTRBZBF)->ZBF_SEQ
            EndIf

               ZBF->(RecLock("ZBF",.T.))
               For nI := 1 To (_cTRBZBF)->(FCount())
                  _cCampo:=(_cTRBZBF)->(FIELDNAME(nI))//GRAVA _cTRBZBF NO ZBF
                  ZBF->&(_cCampo) := (_cTRBZBF)->(FieldGet(nI))
               Next nI

               For nI := 1 To ZBC->(FCount())
                  _cCampo:=StrTran(ZBC->(FIELDNAME(nI)),"ZBC_","ZBF_")//GRAVA ZBC NO ZBF
                  ZBF->&(_cCampo) := ZBC->(FieldGet(nI))
               Next nI

               ZBF->ZBF_FILIAL := ZBC->ZBC_FILIAL   // Filial do Sistema
               ZBF->ZBF_OPER   := ZBC->ZBC_OPERAC   // Tipo de Operação
               ZBF->ZBF_DTENT  := ZBC->ZBC_DTENT    // Data de Entrega
               ZBF->ZBF_PEDCLI := ZBC->ZBC_PEDCOM	// Nr.Pedido do Cliente
               ZBF->ZBF_PEDCOM := ZBC->ZBC_PEDCOM	// Nr.Pedido de Compras Cliente
               ZBF->ZBF_CLIENT := ZBC->ZBC_CLIENT	// Codigo do Cliente
               ZBF->ZBF_LOJACL := ZBC->ZBC_LOJACL	// Loja do Cliente
               ZBF->(MSUnLock())

            (_cTRBZBF)->(DBSkip())
         EndDo

      End Transaction

      U_ITMsg("Geração do Pré-Pedido de Vendas concluida!","Atenção","",2)

   EndIf

   (_cTRBZBD)->(DBCloseArea())
   (_cTRBZBF)->(DBCloseArea())

End Sequence

FWRestArea(_aArea)
FWRestArea(_aAreaZBC)
FWRestArea(_aAreaZBD)
FWRestArea(_aAreaZBE)
FWRestArea(_aAreaZBF)

Return

/*
===============================================================================================================================
Programa----------: AOMS132D
Autor-------------: Julio de Paula Paz
Data da Criacao---: 14/03/2022
Descrição---------: Gera o Pré-Pedido de Vendas com base na quantidade de Pallets o Pedido de compras do Cliente.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS132D()

Local _nSeq      As numeric
Local _nPaletes  As numeric
Local _nQtdPalet As numeric
Local _nI        As numeric
Local _nX        As numeric
Local nI         As numeric
Local _nQtd      As numeric
Local _nQtd2     As numeric
Local _nValorTot As numeric
Local _nTotalP   As numeric
Local _aRestPale As array

Private _aItens As array

_nSeq      := 1
_aRestPale := {}

Begin Sequence //Não retirar

If ! U_ITMsg("Confirma a geração do Pré-Pedido de Vendas?" ,"Atenção", ,3,2, 2)
   Break
EndIf

ProcRegua(0)

IncProc("Gerando Pre-Pedidos de Vendas....")

(_cTRBZBD)->(DBGoTop())

_nTotItZBD := 0

While ! (_cTRBZBD)->(Eof())
   _nTotItZBD += 1  // Armazena o total de itens da tabela ZBD.

   (_cTRBZBD)->(DBSkip())
EndDo

(_cTRBZBD)->(DBGoTop())

//=============================================================================
// Quantidade de Paletes do Veículo > Total de Paletes do Pedido de Compras.
//=============================================================================
IncProc("Gerando Pre-Pedidos de Vendas....")

If _nPaletVeic >= _nTotPallet

   (_cTRBZBD)->(DBGoTop())
   While ! (_cTRBZBD)->(Eof())

      (_cTRBZBF)->(DbAppend())
      For nI := 1 To (_cTRBZBD)->(FCount())
            _cCampo:=StrTran((_cTRBZBD)->(FIELDNAME(nI)),"ZBD_","ZBF_")
            (_cTRBZBF)->&(_cCampo) := (_cTRBZBD)->(FieldGet(nI))
      Next nI

      (_cTRBZBF)->ZBF_PEDCOM := M->ZBC_PEDCOM           //"C", 20, 0 // Pedido de Compras
      (_cTRBZBF)->ZBF_SEQ    := StrZero(_nSeq,3)        //"C", 2 , 0 // Sequencia
      (_cTRBZBF)->WK_UNSVEN  := (_cTRBZBD)->ZBD_UNSVEN  //"N", 9 , 3 // Qtd. Segunda Unidade Med.
      (_cTRBZBF)->WK_QTDVEN  := (_cTRBZBD)->ZBD_QTDVEN  //"N", 13, 3 // Qtd. Primeira Unidade Medida
      (_cTRBZBF)->WK_QTDPAL  := (_cTRBZBD)->WK_QTDPAL   //"N", 3 , 0 // Quantidade de Paletes
      (_cTRBZBF)->WK_QTDPPAL := (_cTRBZBD)->WK_QTDPPAL  //"N", 13, 3 // Quantidade por Palete

      (_cTRBZBD)->(DBSkip())
   EndDo

   Break // GERA APENAS UM PEDIDO PARA O VEÍCULO SELECIONADO.

EndIf

//==================================================================
// Quantidade de itens < Quantidade de Paletes do Veiculo
//==================================================================
IncProc("Gerando Pre-Pedidos de Vendas....")

//If _nTotItZBD < _nPaletVeic
   _aItens := {}

   (_cTRBZBD)->(DBGoTop())
   While ! (_cTRBZBD)->(Eof())
      aAdd(_aItens, {(_cTRBZBD)->ZBD_ITEM  ,;  // Item                                  // 01
                     (_cTRBZBD)->ZBD_PRODUT,;  // Codigo do Produto                     // 02
                     (_cTRBZBD)->ZBD_QTDPAL,;  // Quantidade de Paletes                 // 03 *
                     (_cTRBZBD)->WK_QTDPAL ,;  // Quantidade de Paletes                 // 04
                     (_cTRBZBD)->WK_QTDPPAL,;  // Quantidade por Palete                 // 05
                                       0,;      // Quantidade do item para Pré-Pedido    // 06 *
                     (_cTRBZBD)->(Recno()),;   // Recno da tabela (_cTRBZBD)            // 07
                     .T.               })      // Continua a gerar itens de Pré-Pedido  // 08

      (_cTRBZBD)->(DBSkip())
   EndDo

   nCapCarreta:=_nPaletVeic
   aCarretas:={}
   // Para cada produto
   For nI := 1 To Len(_aItens)

         // Calcular quantas carretas completas são necessárias
         nQtdCarretas := Int(_aItens[nI,3] / nCapCarreta)
         // Calcular paletes restantes
         nRestoPaletes := _aItens[nI,3] - (nQtdCarretas * nCapCarreta)


         // Gerar carretas completas
         If nQtdCarretas > 0
            // Criar carretas completas
            For _nI := 1 To nQtdCarretas
                  _aItens[nI][6] := nCapCarreta // Atualiza a quantidade do item para o pré-pedido
                  aAdd(aCarretas, aClone(_aItens[nI]) )
            Next
         EndIf

         // Se houver paletes restantes
         If nRestoPaletes > 0
            // Criar carreta com restante
            _aItens[nI][6] := nRestoPaletes // Atualiza a quantidade do item para o pré-pedido
            aAdd(aCarretas, aClone(_aItens[nI]) )
         EndIf
      Next
   // Calcula a quantidade de pré-pedidos de Vendas que serão gerados.
   _nQtdPalet := _nTotalP    // Total de Palete por Pré-Pedido de Vendas.
   _nPaletes  := _nTotPallet // Total de Palete do Pedido de Compras.

   // Cria os pré-pedidos de Vendas em Tabelas temporárias (Works).
   SB1->(DBSetOrder(1))

   _aItens := aCarretas // ATRIBUI O ARRAY DE ITENS DA CARRETA ATUAL

   For _nX := 1 To Len(_aItens)

      (_cTRBZBD)->(DBGoTo(_aItens[_nX,7]))

      _nRestPale := 0  // Quantidade de Paletes residuais
      _aRestPale := {}

      If (_cTRBZBD)->WK_QTDPAL == 0
         (_cTRBZBD)->(DBSkip())
         Loop
      EndIf

      _nQtd2:= _aItens[_nX,6] * (_cTRBZBD)->WK_QTDPPAL // Quantidade de Palete por Item x Quantidades por Palete
      SB1->(MsSeek(xFilial("SB1")+(_cTRBZBD)->ZBD_PRODUT))

      _nfator:=SB1->B1_CONV
      If _nfator = 0
         If SB1->B1_I_QQUEI == 'S' .And. SB1->B1_I_FATCO > 0
            _nfator := SB1->B1_I_FATCO
         EndIf
      EndIf
      
      If SB1->B1_TIPCONV == "M"
         _nQtd  := _nQtd2 / _nfator
      Else
         _nQtd  := _nQtd2 * _nfator
      EndIf

      _nValorTot := (_cTRBZBD)->ZBD_PRCVEN * _nQtd

      (_cTRBZBF)->(DbAppend())
      For nI := 1 To (_cTRBZBD)->(FCount())
         _cCampo:=StrTran((_cTRBZBD)->(FIELDNAME(nI)),"ZBD_","ZBF_")
         (_cTRBZBF)->&(_cCampo) := (_cTRBZBD)->(FieldGet(nI))
      Next nI

      (_cTRBZBF)->ZBF_PEDCOM := M->ZBC_PEDCOM                //"C", 20, 0 // Pedido de Compras
      (_cTRBZBF)->ZBF_SEQ    := StrZero(_nSeq,3)             //"C", 2 , 0 // Sequencia
      (_cTRBZBF)->ZBF_UNSVEN := _nQtd2                       //"N", 9 , 3 // Qtd. Segunda Unidade Med.
      (_cTRBZBF)->ZBF_QTDVEN := _nQtd                        //"N", 13, 3 // Qtd. Primeira Unidade Medida
      (_cTRBZBF)->ZBF_VALOR  := _nValorTot                   //"N", 12, 2 // Valor Total
      (_cTRBZBF)->ZBF_QTDPAL := _aItens[_nX,6]               //If(_aItens[_nX,3] < _aItens[_nX,6],_aItens[_nX,3],_aItens[_nX,6]) // _aItens[_nX,6] // Quantidade de Palete por Item//(_cTRBZBD)->ZBD_QTDPAL
      (_cTRBZBF)->WK_UNSVEN  := (_cTRBZBD)->ZBD_UNSVEN       //"N", 9 , 3 // Qtd. Segunda Unidade Med.
      (_cTRBZBF)->WK_QTDVEN  := (_cTRBZBF)->ZBF_QTDVEN       //_nQtd                 //"N", 13, 3 // Qtd. Primeira Unidade Medida
      (_cTRBZBF)->WK_QTDPAL  := (_cTRBZBF)->ZBF_QTDPAL       //If(_aItens[_nX,3] < _aItens[_nX,6],_aItens[_nX,3],_aItens[_nX,6]) // _aItens[_nX,6] // Quantidade de Paletes
      (_cTRBZBF)->WK_QTDPPAL := (_cTRBZBD)->WK_QTDPPAL       //"N", 13, 3 // Quantidades por Paletes

      _nSeq += 1
   Next _nX

   Break // Gera apenas as Works dos pré-pedidos de Vendas que possuem quantidade de itens menores que as quantidades de Paletes do tipo de veículo.

End Sequence

(_cTRBZBF)->(DBGoTop())

_lBtnGerPr := .T.  // Bloqueia botão gerar Pré-Pedido de vendas.
_lTipoVeic := .T.  // Bloqueia combobox tipo de veiculo.

_oGetDBF:ForceRefresh()

Return

/*
===============================================================================================================================
Programa----------: AOMS132L
Autor-------------: Julio de Paula Paz
Data da Criacao---: 14/03/2022
Descrição---------: Gera o Pré-Pedido de Vendas com base na quantidade de Pallets o Pedido de compras do Cliente.
Parametros--------: _nRestoP = Quantidade de Paletes residuais.
                    _aRestPale = 1 = Posição de _aItens
                               = 2 = _nRestoP = Quantidade de Paletes residuais.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS132L(_nRestoP As numeric, _aRestPale As array)
 Local _nI          As numeric
 Local _nSobraQtd   As numeric
 Local _nResiduo    As numeric
 Local _nX          As numeric
 Local _nRestoPalet As numeric
 Local _lTemItem    As logical

 _lTemItem := .F.
 _nResiduo := _nRestoP
 For _nI := 1 To Len(_aItens)
    If _aItens[_nI,8] // Continua a gerar itens de Pré-Pedido de vendas.

       _lTemItem := .T.

       If _aItens[_nI,3] > (_aItens[_nI,6] + _nResiduo) // Quantidade de Palete disponivel > (Quantidade de Palete por item + Residuo)
          _aItens[_nI,6] := _aItens[_nI,6] + _nResiduo
          Exit
       ElseIf _aItens[_nI,3] > _aItens[_nI,6] // Quantidade de Palete disponivel > (Quantidade de Palete por item)
          _nSobraQtd     := _aItens[_nI,6] + _nResiduo - _aItens[_nI,3]
          _aItens[_nI,6] := _aItens[_nI,3]
          _nResiduo := _nSobraQtd
       ElseIf _aItens[_nI,3] <= _nResiduo
          _nSobraQtd     := _aItens[_nI,3] // _nResiduo
          _aItens[_nI,6] := _aItens[_nI,3] // _nResiduo
          _nResiduo := _aItens[_nI,3]
       ElseIf _aItens[_nI,3] <= _aItens[_nI,6]
          _nSobraQtd     := _aItens[_nI,3]
          _aItens[_nI,6] := _aItens[_nI,3]
          _nResiduo := _aItens[_nI,3]
       EndIf
    EndIf
 Next _nI

 If ! _lTemItem
    For _nI := 1 To Len(_aRestPale)
        _nX          := _aRestPale[_nI,1]
        _nRestoPalet := _aRestPale[_nI,2]
    Next _nI

    _aItens[_nX,6] := _aItens[_nX,3]
 EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS132N
Autor-------------: Julio de Paula Paz
Data da Criacao---: 23/03/2022
Descrição---------: Rotina de manutenção de Quantidades e Vinculação de Pré-Pedidos de vendas.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS132N()

Local _cNomeTipoV As char
Local _cVeiculo   As char
Local _aSizeAut   As array
Local nI          As numeric
Local _nLinha     As numeric
Local _nOpc       As numeric
Local nUsado      As numeric
Local _aArea	   AS array
Local _aAreaZBC   AS array
Local _aAreaZBD   AS array
Local _aAreaZBE   AS array
Local _aAreaZBF   AS array

Private aHeader     As array
Private aRotina     As array
Private _aDadosZBD  As array
Private _nTotPallet As numeric
Private _nTotPalZBD As numeric
Private _nPaletVeic As numeric
Private _oTotPallet As object
Private _oTipoVeic  As object
Private _oGetTRBF   As object
Private _OBtnGrava  As object
Private _OBtnSair   As object
Private _cFilPedVe  As char
Private _cTRBZBF    As char
Private _lTipoVeic  As logical
Private Altera      As logical
Private Inclui      As logical

aHeader     := {}
aRotina     := {}
_nTotPallet := 0
_nPaletVeic := 0
_nOpc       := 0
Altera      := .T.
Inclui      := .F.
_aSizeAut   := MsAdvSize(.T.)
_aArea	     := FWGetArea()
_aAreaZBC   := ZBC->(GetArea())
_aAreaZBD   := ZBD->(GetArea())
_aAreaZBE   := ZBE->(GetArea())
_aAreaZBF   := ZBF->(GetArea())

Begin Sequence

ZBE->(DBSetOrder(2))
ZBF->(DBSetOrder(3))
If !ZBE->(MsSeek(xFilial("ZBE")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL))) .And. !ZBF->(MsSeek(xFilial("ZBF")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL)))
   U_ITMsg("Não existem Pre-Pedidos de Vendas Cadastrados para realização de manutenção.","Atenção","",1)
   Break
EndIf

ZBF->(MsSeek(xFilial("ZBF")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL)))
If !Empty(ZBF->ZBF_PVPROT)
   U_ITMsg("Pre-Pedidos de Vendas já efetivados.","Atenção",'Acesse a opção "Visualizar Pedidos Gerados".',3)
   Break
EndIf

_cFilPedVe := M->ZBC_FLFNC//Space(2)

//=======================================================================
// Carrega os itens da tabela ZBD para validação de Quantidades
//=======================================================================
ZBD->(DBSetOrder(1))
ZBD->(MsSeek(xFilial("ZBD")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL)))

_aDadosZBD := {}
_nTotPallet := 0

While ! ZBD->(Eof()) .And. ZBD->(ZBD_FILIAL+ZBD_PEDCOM+ZBD_CLIENT+ZBD_LOJACL) == xFilial("ZBD")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL)

   aAdd(_aDadosZBD, {ZBD->ZBD_ITEM                               ,;// Item
                     ZBD->ZBD_PRODUT                             ,;// Codigo do Produto
                     Trans(ZBD->ZBD_UNSVEN,"@E 999,999,999.9999"),;// Qtd. Segunda Unidade Med.
                     ZBD->ZBD_SEGUM                              ,;// Segunda Unidade Medida
                     Trans(ZBD->ZBD_QTDVEN,"@E 999,999,999.9999"),;// Qtd. Primeira Unidade Medida
                     ZBD->ZBD_UM                                 ,;// Primeira Unidade Medida
                     Trans(ZBD->ZBD_PRCVEN,"@E 999,999,999.99")  ,;// Preço Unitário Liquido
                     Trans(ZBD->ZBD_VALOR ,"@E 999,999,999.99")  ,;// Valor Total
                     Trans(ZBD->ZBD_QTDPAL,"@E 999,999,9999")    ,;// Quantidade de Paletes
                     ZBD->ZBD_DESCRI                             })// Descrição do Produto

   _nTotPallet += ZBD->ZBD_QTDPAL

   ZBD->(DBSkip())
EndDo
_nTotPalZBD:=_nTotPallet

//=======================================================================
// Carrega os dados de capa para exibição da tela.
//=======================================================================
_nPaletVeic  := Posicione("DUT",1,xFilial("DUT")+ZBE->ZBE_TPVEIC,"DUT_QTUNIH")//Alterar onde está utilizado o campo DUT_I_QPAL para DUT_QTUNIH (Qtd.Unitiz.Horizontal) chamado 37652
_cNomeTipoV  := Posicione("DUT",1,xFilial("DUT")+ZBE->ZBE_TPVEIC,"DUT_DESCRI")
_cVeiculo    := ZBE->ZBE_TPVEIC + "-" + _cNomeTipoV

For nI := 1 To ZBC->(FCount())
      M->&(ZBC->(FIELDNAME(nI))) := ZBC->(FieldGet(nI))
Next nI
M->ZBC_TRCNF  := If(ZBC->ZBC_TRCNF=="S","Sim","Nao")

//===============================================================
// Work com a capa dos pré-pedidos de Vendas.
//===============================================================
_aStruct2 := FWSX3Util():GetListFieldsStruct( "ZBF" , .T.  )//Com campos virtuais

aAdd(_aStruct2, {"WK_PEDPROT", "C", 06, 0}) // Pedido de Vendas Protheus
aAdd(_aStruct2, {"WK_UNSVEN" , "N", 09, 3}) // Qtd. Segunda Unidade Med. Atual
aAdd(_aStruct2, {"WK_QTDVEN" , "N", 13, 3}) // Qtd. Primeira Unidade Medida Atual 
aAdd(_aStruct2, {"WK_QTDPAL" , "N", 03, 0}) // Qtd. Primeira Unidade Medida Atual 
aAdd(_aStruct2, {"WK_RECNO"  , "N", 10, 0}) // Recno do Item ZBF
aAdd(_aStruct2, {"DELETED"   , "L" ,01 ,0})  // DELETE DO MSGETDB

_cTRBZBF:=GetNextAlias()
_oTemp2:= FWTemporaryTable():New(_cTRBZBF, _aStruct2 )
_oTemp2:AddIndex( "01", {"ZBF_PEDCOM", "ZBF_SEQ" , "ZBF_AGRUPA" , "ZBF_ITEM"} )
_oTemp2:AddIndex( "02", {"ZBF_PEDCOM", "ZBF_ITEM"} )//Para dar MsSeek na U_AOMS132O("TUDOOK_MANUT")
_oTemp2:Create()

ZBF->(DBSetOrder(3)) // ZBF_FILIAL+ZBF_PEDCOM+ZBF_CLIENT+ZBF_LOJACL+ZBF_SEQ
ZBF->(MsSeek(xFilial("ZBF")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL)))

While ! ZBF->(Eof()) .And. ZBF->(ZBF_FILIAL+ZBF_PEDCOM+ZBF_CLIENT+ZBF_LOJACL) == xFilial("ZBF")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL)

   (_cTRBZBF)->(DbAppend())
   For nI := 1 To ZBF->(FCount())
         (_cTRBZBF)->&(ZBF->(FIELDNAME(nI))) := ZBF->(FieldGet(nI))
   Next nI
   (_cTRBZBF)->WK_QTDVEN := ZBF->ZBF_QTDVEN   // Qtd. Primeira Unidade Medida ATUAL
   (_cTRBZBF)->WK_UNSVEN := ZBF->ZBF_UNSVEN   // Qtd. Segunda Unidade Med. ATUAL
   (_cTRBZBF)->WK_QTDPAL := ZBF->ZBF_QTDPAL   // Qtd. Paletes ATUAL
   (_cTRBZBF)->WK_PEDPROT:= ZBF->ZBF_PVPROT   // Pedido de Vendas Protheus
   (_cTRBZBF)->WK_RECNO  := ZBF->(Recno())    // Recno do Item ZBD
   ZBF->(DBSkip())

EndDo

// MONTA AHEADER DO MSGETDB.
aHeader:={}
_aSX3 := FWSX3Util():GetAllFields( "ZBF" ,  .F. )
For nUsado := 1 To Len(_aSX3)
   _cCampo:=_aSX3[nUsado]
   If _cCampo $ _cCpos_Nao_Usados
      Loop
   EndIf
   _cUsado:=GetSX3Cache(_cCampo,"X3_USADO")
   If X3USO(_cUsado)                                       //Estrutura do aHeader do MsNewGetDados      |
      aAdd( aHeader , {GetSX3Cache(_cCampo,"X3_TITULO")  ,;//aHeader[01] - X3_TITULO  | Título
                        GetSX3Cache(_cCampo,"X3_CAMPO")   ,;//aHeader[02] - X3_CAMPO   | Campo
                        GetSX3Cache(_cCampo,"X3_PICTURE") ,;//aHeader[03] - X3_PICTURE | Picture
                        GetSX3Cache(_cCampo,"X3_TAMANHO") ,;//aHeader[04] - X3_TAMANHO | Tamanho
                        GetSX3Cache(_cCampo,"X3_DECIMAL") ,;//aHeader[05] - X3_DECIMAL | Decimal
                        GetSX3Cache(_cCampo,"X3_VALID")   ,;//aHeader[06] - X3_VALID   | Validação
                        _cUsado                           ,;//aHeader[07] - X3_USADO   | Usado
                        GetSX3Cache(_cCampo,"X3_TIPO")    ,;//aHeader[08] - X3_TIPO    | Tipo
                        GetSX3Cache(_cCampo,"X3_ARQUIVO") ,;//aHeader[09] - X3_ARQUIVO
                        GetSX3Cache(_cCampo,"X3_CONTEXT") })//aHeader[10] - X3_CONTEXT | Contexto (R,V)
   EndIf
   If _cCampo = "ZBF_UNSVEN"
      aAdd(aHeader,{"Qtd.Atual.2 Un.Med."                 ,;   //aHeader[01] - X3_TITULO  | Título
                     "WK_UNSVEN"                           ,;   //aHeader[02] - X3_CAMPO   | Campo
                     GetSX3Cache(_cCampo,"X3_PICTURE")     ,;   //aHeader[03] - X3_PICTURE | Picture
                     GetSX3Cache(_cCampo,"X3_TAMANHO")     ,;   //aHeader[04] - X3_TAMANHO | Tamanho
                     GetSX3Cache(_cCampo,"X3_DECIMAL")     ,;   //aHeader[05] - X3_DECIMAL | Decimal
                     GetSX3Cache(_cCampo,"X3_VALID")       ,;   //aHeader[06] - X3_VALID   | Validação
                     GetSX3Cache(_cCampo,"X3_USADO")       ,;   //aHeader[07] - X3_USADO   | Usado
                     GetSX3Cache(_cCampo,"X3_TIPO")        ,;   //aHeader[08] - X3_TIPO    | Tipo
                     GetSX3Cache(_cCampo,"X3_ARQUIVO")     ,;   //aHeader[09] - X3_ARQUIVO
                     GetSX3Cache(_cCampo,"X3_CONTEXT")     })   //aHeader[10] - X3_CONTEXT | Contexto (R,V)
   ElseIf _cCampo = "ZBF_QTDVEN"
      aAdd(aHeader,{"Qtd.Atual 1 Un Med"                 ,;    //aHeader[01] - X3_TITULO  | Título
                     "WK_QTDVEN"                          ,;    //aHeader[02] - X3_CAMPO   | Campo
                     GetSX3Cache(_cCampo,"X3_PICTURE")    ,;    //aHeader[03] - X3_PICTURE | Picture
                     GetSX3Cache(_cCampo,"X3_TAMANHO")    ,;    //aHeader[04] - X3_TAMANHO | Tamanho
                     GetSX3Cache(_cCampo,"X3_DECIMAL")    ,;    //aHeader[05] - X3_DECIMAL | Decimal
                     GetSX3Cache(_cCampo,"X3_VALID")      ,;    //aHeader[06] - X3_VALID   | Validação
                     GetSX3Cache(_cCampo,"X3_USADO")      ,;    //aHeader[07] - X3_USADO   | Usado
                     GetSX3Cache(_cCampo,"X3_TIPO")       ,;    //aHeader[08] - X3_TIPO    | Tipo
                     GetSX3Cache(_cCampo,"X3_ARQUIVO")    ,;    //aHeader[09] - X3_ARQUIVO
                     GetSX3Cache(_cCampo,"X3_CONTEXT")    })    //aHeader[10] - X3_CONTEXT | Contexto (R,V)
   ElseIf _cCampo = "ZBF_QTDPAL"
      aAdd(aHeader,{"Qtd.Atual Pallets"                  ,;    //aHeader[01] - X3_TITULO  | Título
                     "WK_QTDPAL"                          ,;    //aHeader[02] - X3_CAMPO   | Campo
                     GetSX3Cache(_cCampo,"X3_PICTURE")    ,;    //aHeader[03] - X3_PICTURE | Picture
                     GetSX3Cache(_cCampo,"X3_TAMANHO")    ,;    //aHeader[04] - X3_TAMANHO | Tamanho
                     GetSX3Cache(_cCampo,"X3_DECIMAL")    ,;    //aHeader[05] - X3_DECIMAL | Decimal
                     GetSX3Cache(_cCampo,"X3_VALID")      ,;    //aHeader[06] - X3_VALID   | Validação
                     GetSX3Cache(_cCampo,"X3_USADO")      ,;    //aHeader[07] - X3_USADO   | Usado
                     GetSX3Cache(_cCampo,"X3_TIPO")       ,;    //aHeader[08] - X3_TIPO    | Tipo
                     GetSX3Cache(_cCampo,"X3_ARQUIVO")    ,;    //aHeader[09] - X3_ARQUIVO
                     GetSX3Cache(_cCampo,"X3_CONTEXT")    })    //aHeader[10] - X3_CONTEXT | Contexto (R,V)
   EndIf

Next nUsado

_cCampo:="ZBF_PVPROT"
aAdd(aHeader,{"Nr.Ped.Vendas Protheus"         ,;   //aHeader[01] - X3_TITULO  | Título
               "WK_PEDPROT"                     ,;   //aHeader[02] - X3_CAMPO   | Campo
               GetSX3Cache(_cCampo,"X3_PICTURE"),;   //aHeader[03] - X3_PICTURE | Picture
               GetSX3Cache(_cCampo,"X3_TAMANHO"),;   //aHeader[04] - X3_TAMANHO | Tamanho
               GetSX3Cache(_cCampo,"X3_DECIMAL"),;   //aHeader[05] - X3_DECIMAL | Decimal
               GetSX3Cache(_cCampo,"X3_VALID")  ,;   //aHeader[06] - X3_VALID   | Validação
               GetSX3Cache(_cCampo,"X3_USADO")  ,;   //aHeader[07] - X3_USADO   | Usado
               GetSX3Cache(_cCampo,"X3_TIPO")   ,;   //aHeader[08] - X3_TIPO    | Tipo
               GetSX3Cache(_cCampo,"X3_ARQUIVO"),;   //aHeader[09] - X3_F3      | F3
               GetSX3Cache(_cCampo,"X3_CONTEXT")})   //aHeader[10] - X3_CONTEXT | Contexto (R,V)

// Configurações iniciais
_aObjects := {}
aAdd( _aObjects, { 315,  50, .T., .T. } )
aAdd( _aObjects, { 100, 100, .T., .T. } )
_aInfo   := { _aSizeAut[ 1 ], _aSizeAut[ 2 ], _aSizeAut[ 3 ], _aSizeAut[ 4 ], 3, 3 }
_aPosObj := MsObjSize( _aInfo, _aObjects, .T. )

aRotina := {}
aAdd(aRotina,{"","",0,4})

Inclui     := .F.
Altera     := .T.
_lTipoVeic := .F.
bValTudo   := {|| _lRet:=.F. ,  FWMsgRun(,{|oproc| _lRet:=U_AOMS132O("TUDOOK_MANUT") },"Aguarde...","Validando Pedidos...")   , _lRet  }

While .T.

   _nOpc := 0
   (_cTRBZBF)->(DBGoTop())

   DEFINE MSDIALOG _oDlgManut TITLE "Manutenção Pré-Pedido de Vendas" FROM _aSizeAut[7],00 To _aSizeAut[6], _aSizeAut[5] PIXEL

         _nLinha := 15
         @ _nLinha, 10 Say "Ped.Compras"	Pixel Size  030,012 Of _oDlgManut
         @ _nLinha, 60 MSGet M->ZBC_PEDCOM  Pixel Size 040,012 WHEN .F. Of _oDlgManut

         @ _nLinha, 115 Say "Tipo de Veiculo"	Pixel Size 040,012 Of _oDlgManut
         @ _nLinha, 170 MSGet _cVeiculo  Pixel Size 130,012 WHEN .F. Of _oDlgManut

         @ _nLinha, 405 Say "Total Pallets Veiculo:"	Pixel Size  080,012 Of _oDlgManut
         @ _nLinha, 465 MSGet _nPaletVeic Pixel Size 040,012 WHEN .F. Of _oDlgManut

         @ _nLinha, 520 Say "Total de Pallets do Pedido:"	Pixel Size  080,012 Of _oDlgManut
         @ _nLinha, 590 MSGet _oTotPallet Var _nTotPallet Pixel Size 040,012 WHEN .F. Of _oDlgManut

         _nLinha += 20
         @ _nLinha, 10 Say "Troca Nota"	Pixel Size 030,012 Of _oDlgManut
         @ _nLinha, 60 MSGet M->ZBC_TRCNF Pixel Size 040,012 WHEN .F. Of _oDlgManut

         @ _nLinha, 115 Say "Filial Faturamento"	Pixel Size 040, 020 Of _oDlgManut
         @ _nLinha, 170 MSGet M->ZBC_FLFNC Pixel Size 040,009 WHEN .F. Of _oDlgManut

         @ _nLinha, 255 Say "Filial Carregamento"	Pixel Size 040,020 Of _oDlgManut
         @ _nLinha, 305 MSGet M->ZBC_FILFT Pixel Size 100,012 WHEN .F. Of _oDlgManut


         _nLinha += 20
         @ _nLinha, 10 Say "Cliente"	Pixel Size 030,012 Of _oDlgManut
         @ _nLinha, 60 MSGet M->ZBC_CLIENT Pixel Size 040,012 WHEN .F. Of _oDlgManut

         @ _nLinha, 115 Say "Loja Cliente"	Pixel Size 040, 012 Of _oDlgManut
         @ _nLinha, 170 MSGet M->ZBC_LOJACL Pixel Size 040,009 WHEN .F. Of _oDlgManut

         @ _nLinha, 255 Say "Nome Cliente"	Pixel Size 040,012 Of _oDlgManut
         @ _nLinha, 305 MSGet M->ZBC_NOME Pixel Size 100,012 WHEN .F. Of _oDlgManut

         _nLinha += 20

         @ _nLinha, 10 Say "Estado"	Pixel Size 030,012 Of _oDlgManut
         @ _nLinha, 60 MSGet M->ZBC_EST Pixel Size 040,012 WHEN .F. Of _oDlgManut

         @ _nLinha, 115 Say "Municipio"	Pixel Size 030,012 Of _oDlgManut
         @ _nLinha, 170 MSGet M->ZBC_MUN Pixel Size 060,012 WHEN .F. Of _oDlgManut

         @ _nLinha, 255 Say "CEP"	Pixel Size 030,012 Of _oDlgManut
         @ _nLinha, 305 MSGet M->ZBC_CEP Pixel Size 040,012 WHEN .F. Of _oDlgManut

         @ _nLinha, 375 Say "Bairro"	Pixel Size 030,012 Of _oDlgManut
         @ _nLinha, 415 MSGet M->ZBC_BAIREN Pixel Size 080,012 WHEN .F. Of _oDlgManut

         _nLinha += 20

         @ _nLinha, 10 Say "DDD"	Pixel Size 030,012 Of _oDlgManut
         @ _nLinha, 60 MSGet M->ZBC_DDD Pixel Size 040,012 WHEN .F. Of _oDlgManut

         @ _nLinha, 115 Say "Telefone"	Pixel Size 030,012 Of _oDlgManut
         @ _nLinha, 170 MSGet M->ZBC_TELEFO Pixel Size 040,012 WHEN .F. Of _oDlgManut

         @ _nLinha, 255 Say "Tp.Operação"	Pixel Size 040,012 Of _oDlgManut
         @ _nLinha, 305 MSGet M->ZBC_OPERAC Pixel Size 040,012 WHEN .F. Of _oDlgManut

         @ _nLinha, 375 Say "Tipo Pedido"	Pixel Size 040,012 Of _oDlgManut
         @ _nLinha, 415 MSGet M->ZBC_TIPO Pixel Size 040,012 WHEN .F. Of _oDlgManut

         @ _nLinha, 475 Say "Data Entrega"	Pixel Size 040,012 Of _oDlgManut
         @ _nLinha, 515 MSGet M->ZBC_DTENT Pixel Size 040,012 WHEN .F. Of _oDlgManut

         @ _nLinha, 570 Say "Vendedor"	Pixel Size 040,012 Of _oDlgManut
         @ _nLinha, 605 MSGet M->ZBC_VEND1 Pixel Size 040,012 WHEN .F. Of _oDlgManut
         _nLinha += 20

         //Lista de Campos editaveis: PROCURE #EDITAVEL para ver os campos que devem ser copiados, campos novo devem ser adicionados aqui e lá
         _aAlter:={'ZBF_QTDPAL','ZBF_UNSVEN','ZBF_QTDVEN', 'ZBF_AGRUPA','ZBF_AGENDA','ZBF_DTENT','ZBF_SENHA','ZBF_OBPED','ZBF_MENNOT','ZBF_TRCNF','ZBF_FLFNC','ZBF_FILFT',"ZBF_CONDPG","ZBF_LOCAL","ZBF_OPER","ZBF_DOCA","ZBF_HOREN"}
         
         // BOTÃO '3-Manutenção e Efetivação Pre-Pedidos Vendas' Action 'U_AOMS132N
         
         //        //MsGetDB () :New( <nTop>, < nLeft>, < nBottom>       , < nRight>         ,< nOpc>,cLinhaOk, [ cTudoOk]                  ,[ cIniCpos], [ lDelete] , [ aAlter],[ nFreeze], [ lEmpty], [ uPar1], < cTRB>  , [ cFieldOk],[uPar2], [ lAppend], [ oWnd]   , [ lDisparos], [ uPar3], [ cDelOk], [ cSuperDel] ) --> oObj
         _oGetTRBF := MsGetDB():New(_nLinha, 0       , _aPosObj[2,3]-20 , _aPosObj[2,4]     , 1     ,        , "U_AOMS132O('TUDOOK_MANUT')", ""        , .T.        , _aAlter  , 0        , .F.      ,         , _cTRBZBF ,            ,       , .F.       , _oDlgManut, .T.         ) //     ,         ,""        , "")

         _oGetTRBF:oBrowse:bAdd := {||.F.} // não inclui novos itens MsGetDb ()

         nColB:=5
         @ _aPosObj[2,3]-15,nColB BUTTON _OBtnGrava PROMPT "3-Gravar/Efetivação Pre-PVs" SIZE 80, 013 OF _oDlgManut ACTION ( If(EVAL(bValTudo),(_nOpc := 1 ,_oDlgManut:End()),) ) PIXEL
         nColB+=95
         @ _aPosObj[2,3]-15,nColB BUTTON _OBtnGrava PROMPT "Desmembrar 2UM"              SIZE 80, 013 OF _oDlgManut ACTION ( If(AOM132Desm(0)  ,(_nOpc := 2 ,_oDlgManut:End()),) ) PIXEL
         nColB+=95
         @ _aPosObj[2,3]-15,nColB BUTTON _OBtnGrava PROMPT "Ver Itens"                   SIZE 80, 013 OF _oDlgManut ACTION ( U_AOMS132Z("VERITENS")) PIXEL
         nColB+=95
         @ _aPosObj[2,3]-15,nColB BUTTON _OBtnGrava PROMPT "Excluir Pré-Pedidos"         SIZE 80, 013 OF _oDlgManut ACTION ( If(U_AOMS132Z("EXCLUIR_ZBE_ZBF"),(_nOpc := 3 ,_oDlgManut:End()),) ) PIXEL
         nColB+=95
         @ _aPosObj[2,3]-15,nColB BUTTON _OBtnSair  PROMPT "SAIR"	                     SIZE 50, 013 OF _oDlgManut ACTION ( (_nOpc := 0 ,_oDlgManut:End()) ) PIXEL

         If _lTipoVeic
            _oTipoVeic:Disable()
         EndIf

         (_cTRBZBF)->(DBGoTop())
         _oGetTRBF:ForceRefresh( )

   ACTIVATE MSDIALOG _oDlgManut CENTERED

   If _nOpc = 3
      Exit
   EndIf

   If _nOpc = 2
      Loop
   EndIf

   If _nOpc = 0
      If U_ITMsg("Confirma SAIR da manutenção do Pré-Pedido de Vendas?" ,"Atenção","TODAS AS ALTERÇÕES SERÃO PERDIDAS." ,3,2, 2)
         Exit
      EndIf
      Loop
   EndIf

   If _nOpc == 1

      If !U_ITMsg("Confirma a gravação da manutenção do Pré-Pedido de Vendas?" ,"Atenção", ,3,2, 2)
         Loop
      EndIf

      ZBE->(DBSetOrder(2))
      ZBE->(MsSeek(xFilial("ZBE")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL)))

      Begin Transaction

         ZBF->(DBSetOrder(4))//ZBF_FILIAL+ZBF_PEDCOM+ZBF_CLIENT+ZBF_LOJACL+ZBF_AGRUPA+ZBF_PRODUT // INDICE NOVO

         (_cTRBZBF)->(DBGoTop())
         While ! (_cTRBZBF)->(Eof())
            If (_cTRBZBF)->DELETED
               (_cTRBZBF)->(DBSkip())
               Loop
            EndIf
                                          //ZBF_FILIAL+ZBF_PEDCOM+ZBF_CLIENT+ZBF_LOJACL+ZBF_AGRUPA+ZBF_PRODUT
            If (_cTRBZBF)->WK_RECNO = 0       .AND.;
               !Empty((_cTRBZBF)->ZBF_AGRUPA) .AND.;
               ZBF->(MsSeek(xFilial()+ZBC->ZBC_PEDCOM+ZBC->ZBC_CLIENT+ZBC->ZBC_LOJACL+(_cTRBZBF)->ZBF_AGRUPA+(_cTRBZBF)->ZBF_PRODUT)  )

               ZBF->(RecLock("ZBF",.F.))
               ZBF->ZBF_QTDVEN  := ZBF->ZBF_QTDVEN + (_cTRBZBF)->ZBF_QTDVEN
               ZBF->ZBF_UNSVEN  := ZBF->ZBF_UNSVEN + (_cTRBZBF)->ZBF_UNSVEN
               ZBF->ZBF_QTDPAL  := ZBF->ZBF_QTDPAL + (_cTRBZBF)->ZBF_QTDPAL
               ZBF->ZBF_VALOR   := ZBF->ZBF_VALOR  + (_cTRBZBF)->ZBF_VALOR
               ZBF->(MSUnLock())
               (_cTRBZBF)->(DBSkip())
               Loop///********* Loop ***********//////
            EndIf
            If (_cTRBZBF)->WK_RECNO > 0
               ZBF->(DBGoTo((_cTRBZBF)->WK_RECNO))
               ZBF->(RecLock("ZBF",.F.))
            Else
               ZBF->(RecLock("ZBF",.T.))
            EndIf
            For nI := 1 To (_cTRBZBF)->(FCount())
                  ZBF->&((_cTRBZBF)->(FieldName(nI))) := (_cTRBZBF)->(FieldGet(nI))
            Next nI
            ZBF->ZBF_FILGPV:=ZBF->ZBF_FLFNC// FILIAL PARA GERAÇÃO DO PEDIDO DE VENDAS.
            ZBF->(MSUnLock())
            (_cTRBZBF)->(DBSkip())

         EndDo

      End Transaction

      If !U_ITMsg("Confirma a EFETIVAÇÃO dos pré-pedidos de Vendas?" ,"Atenção","GRAVAÇÃO da manutenção do Pré-Pedido de Vendas CONCLUIDA COM SUCESSO",3,2, 2)
         Exit
      EndIf

      _lRet:=.F.
      FWMsgRun(,{|oProc|  _lRet:=U_AOMS132P(oProc) },"AGUARDE...", "GERANDO PEDIDOS... ")
      If !_lRet
         Loop
      EndIf

      //U_ITMsg("Gravação da manutenção do Pré-Pedido de Vendas concluida!","Atenção","",2)

      Exit

   EndIf

EndDo

(_cTRBZBF)->(DBCloseArea())

End Sequence

FWRestArea(_aArea)
FWRestArea(_aAreaZBC)
FWRestArea(_aAreaZBD)
FWRestArea(_aAreaZBE)
FWRestArea(_aAreaZBF)

Return

/*
===============================================================================================================================
Programa----------: AOMS132O
Autor-------------: Julio de Paula Paz
Data da Criacao---: 23/03/2022
Descrição---------: Rotina de validação das manutenções de Quantidades e Vinculação de Pré-Pedidos de vendas.
Parametros--------: _cCampo = Campo que chamou a validação.
Retorno-----------: _lRet = .T. = Validado
                            .F. = Não validado
==============================================================================================================================
*/
User Function AOMS132O(_cCampo As char, nQtde As numeric) As logical

Local _lRet      As logical
Local _nI        As numeric
Local _nRegAtu   As numeric
Local _aDadosZBD As array
Local _aErros    As array
Default nQtde := 2

_lRet     := .T.
_aDadosZBD:= {}
_nRegAtu  := (_cTRBZBF)->(Recno())

Begin Sequence

If _cCampo == "ZBF_AGRUPA"
   If Empty(M->ZBF_AGRUPA)
      Break
   EndIf
   If !ExistCpo("SX5","Z3"+M->ZBF_AGRUPA)
      _lRet := .F.
      Break
   EndIf
   _aItensIgual:={}
   _nRec01:=0
   _nRecno:=(_cTRBZBF)->(RecNo())
   M->ZBF_FLFNC := (_cTRBZBF)->ZBF_FLFNC
   (_cTRBZBF)->(DBGoTop())
   While !(_cTRBZBF)->(Eof())
      If (_cTRBZBF)->DELETED
         (_cTRBZBF)->(DBSkip())
         Loop
      EndIf
      If aScan(_aItensIgual,(_cTRBZBF)->ZBF_FLFNC+(_cTRBZBF)->ZBF_AGRUPA+(_cTRBZBF)->ZBF_PRODUT) = 0 .And. _nRecno <> (_cTRBZBF)->(RecNo())
            aAdd(_aItensIgual,(_cTRBZBF)->ZBF_FLFNC+(_cTRBZBF)->ZBF_AGRUPA+(_cTRBZBF)->ZBF_PRODUT)
      EndIf
      If _nRec01 = 0 .And. M->ZBF_AGRUPA = (_cTRBZBF)->ZBF_AGRUPA
         _nRec01:=(_cTRBZBF)->(RecNo())
      EndIf
      (_cTRBZBF)->(DBSkip())
   EndDo
   If _nRec01 > 0
      (_cTRBZBF)->(DBGoTo(_nRec01))//PRIMEIRA LINHA DO GRUPO SELECIONADO
      For _nI := 1 To (_cTRBZBF)->(FCount())
            M->&((_cTRBZBF)->(FIELDNAME(_nI))) := (_cTRBZBF)->(FieldGet(_nI))
      Next _nI
      (_cTRBZBF)->(DBGoTo(_nRecno)) //LINHA ATUAL
      If aScan(_aItensIgual,M->ZBF_FLFNC + M->ZBF_AGRUPA + (_cTRBZBF)->ZBF_PRODUT)
         U_ITMsg("Esse produto "+AllTrim((_cTRBZBF)->ZBF_PRODUT)+" já está Nesse filial carregamento + veiculo "+M->ZBF_FLFNC+" + "+M->ZBF_AGRUPA ,"Atenção","",1)
         _lRet := .F.
         Break
      EndIf
      //Copia só os Campos editaveis exeto os de quantidades PROCURE #EDITAVEL para ver os campos editaveis, campos novo devem ser adicionados aqui e lá
      (_cTRBZBF)->ZBF_AGENDA:=M->ZBF_AGENDA
      (_cTRBZBF)->ZBF_DTENT :=M->ZBF_DTENT
      (_cTRBZBF)->ZBF_TRCNF :=M->ZBF_TRCNF
      (_cTRBZBF)->ZBF_FLFNC :=M->ZBF_FLFNC
      (_cTRBZBF)->ZBF_FILFT :=M->ZBF_FILFT
      (_cTRBZBF)->ZBF_SENHA :=M->ZBF_SENHA
      (_cTRBZBF)->ZBF_OBPED :=M->ZBF_OBPED
      (_cTRBZBF)->ZBF_MENNOT:=M->ZBF_MENNOT
      (_cTRBZBF)->ZBF_CONDPG:=M->ZBF_CONDPG
      (_cTRBZBF)->ZBF_DOCA  :=M->ZBF_DOCA
      (_cTRBZBF)->ZBF_HOREN :=M->ZBF_HOREN
   EndIf

ElseIf _cCampo == "ZBF_TRCNF"

   If !Pertence("SN",M->ZBF_TRCNF)
      _lRet := .F.
      Break
   EndIf
   If Empty((_cTRBZBF)->ZBF_FLFNC)
      (_cTRBZBF)->ZBF_FLFNC:=cFilAnt
   EndIf
   If M->ZBF_TRCNF = 'S' .And. (_cTRBZBF)->ZBF_FILFT == (_cTRBZBF)->ZBF_FLFNC
      (_cTRBZBF)->ZBF_FILFT:='  '
   ElseIf M->ZBF_TRCNF = 'N'
      (_cTRBZBF)->ZBF_FILFT:=(_cTRBZBF)->ZBF_FLFNC
   EndIf

ElseIf _cCampo == "ZBF_AGENDA" // TIPO DE AGENDAMENTO DO ZBF

   If !U_TipoEntrega(M->ZBF_AGENDA,.T.) .Or. Empty(M->ZBF_AGENDA)

      _lRet:=.F.

   ElseIf MONTH(Date()) != 12 .And.  M->ZBF_AGENDA = 'P'

         (_cTRBZBF)->ZBF_DTENT := SToD(AllTrim(Str((YEAR(Date())+1)))+"0101")-1

   ElseIf MONTH(Date()) = 12 .And.  M->ZBF_AGENDA = 'P'

         (_cTRBZBF)->ZBF_DTENT := SToD(AllTrim(Str((YEAR(Date())+2)))+"0101")-1

   ElseIf !Empty(M->ZBF_AGENDA) .And. M->ZBF_AGENDA $ 'I,O'
         //                              OMSVLDENT(_ddent,_cclient     ,_cloja       ,_cfilft              ,_cpedido,_nret,_lshow,_cFilCarreg,_cOperPedV   ,_cTipoVenda ,_lAchouZG5,_cRegra,_cLocalEmb,_lValSC5)
         (_cTRBZBF)->ZBF_DTENT:=Date()+U_OmsVlDent(      ,M->ZBC_CLIENT,M->ZBC_LOJACL,(_cTRBZBF)->ZBF_FLFNC," "     ,1    ,.F.   ,           ,M->ZBC_OPERAC,M->ZBC_TPVEN,          ,       ,          ,.F.)

   EndIf

ElseIf _cCampo == "ZBF_UNSVEN" // QUANTIDADE SEGUNDA UNIDADE DE MEDIDA #UNSVEN

   _nQtd2    :=  M->ZBF_UNSVEN
   _nPrcVend := (_cTRBZBF)->ZBF_PRCVEN

   If _nQtd2 == 0
      Break
   EndIf

   _cCod := (_cTRBZBF)->ZBF_PRODUT
   SB1->(DBSetOrder(1))
   SB1->(MsSeek(xFilial("SB1")+_cCod))

   _nQtd     := AOMS132CNV(_nQtd2, 2 , 1)//CONVERSÃO
   _cUMPal   := "" //Preenchido na rotina AOMS132CT ()
   _cUMPal2UM:= "" //Preenchido na rotina AOMS132CT ()
   _nQtdPalet:= AOMS132CT(_cCod,_nQtd)  //CALCULO DA QUANTIDADE DE PALETES
   If !Empty(_cUMPal2UM)
      _cUMPal:=_cUMPal2UM
   EndIf

   If _nQtdPalet <> Int(_nQtdPalet)
      U_ITMsg('A quantidade informada na segunda unidade de medida não é multipla das quantidades por palete para este item. '+ _cUMPal+" por palete.","Atenção","",1)
      _lRet := .F.
      Break
   EndIf

   _nValorTot := _nPrcVend * _nQtd
   (_cTRBZBF)->ZBF_QTDVEN := _nQtd
   (_cTRBZBF)->ZBF_QTDPAL := _nQtdPalet
   (_cTRBZBF)->ZBF_VALOR  := _nValorTot

ElseIf _cCampo == "ZBF_QTDVEN"  // QUANTIDADE PRIMEIRA UNIDADE

   _nQtd     := M->ZBF_QTDVEN
   _nPrcVend := (_cTRBZBF)->ZBF_PRCVEN

   If _nQtd == 0
      U_ITMsg('O preenchimento da quantidade do item na primeira unidade de medida é obrigatório.',"Atenção","",1)
      _lRet := .F.
      Break
   EndIf

   _cCod := (_cTRBZBF)->ZBF_PRODUT
   SB1->(DBSetOrder(1))
   SB1->(MsSeek(xFilial("SB1")+_cCod))

   _nQtd2    := AOMS132CNV(_nQtd, 1 , 2)//CONVERSÃO
   _cUMPal   := ""//Preenchido na rotina AOMS132CT ()
   _cUMPal1UM:= ""//Preenchido na rotina AOMS132CT ()
   _nQtdPalet:= AOMS132CT(_cCod,_nQtd)  //CALCULO DA QUANTIDADE DE PALETES
   If !Empty(_cUMPal1UM)
      _cUMPal:=_cUMPal1UM
   EndIf
   If _nQtdPalet <> Int(_nQtdPalet)
      U_ITMsg('A quantidade informada na primeira unidade de medida não é multipla das quantidades por palete para este item. '+_cUMPal+" por palete.","Atenção","",1)
      _lRet := .F.
      Break
   EndIf

   _nValorTot := _nPrcVend *  _nQtd
   (_cTRBZBF)->ZBF_UNSVEN  := _nQtd2
   (_cTRBZBF)->ZBF_QTDPAL  := _nQtdPalet
   (_cTRBZBF)->ZBF_VALOR   := _nValorTot

ElseIf _cCampo == "#ZBF_QTDPAL" // QUANTIDADE DE #PALLET#

   _nQtdPalet:= M->ZBF_QTDPAL
   _nPrcVend := (_cTRBZBF)->ZBF_PRCVEN

   If _nQtdPalet = 0
      Help( ,, 'Atenção'+" ["+DToC(Date())+"] ["+TIME()+"] AOMS132_0B5",, 'O preenchimento da quantidade de Pallet do item é obrigatório.', 1, 0 )
      _lRet := .F.
      Break
   EndIf

   _cCod:= (_cTRBZBF)->ZBF_PRODUT
   SB1->(DBSetOrder(1))
   SB1->(MsSeek(xFilial("SB1")+_cCod))

   _nQtd     := AOMS132CT(_cCod,_nQtdPalet,.T.)// ** CALCULO DA 1a UM
   _nQtd2    := AOMS132CNV(_nQtd, 1 , 2)//CONVERSÃO

   _nValorTot:= _nPrcVend * _nQtd
   (_cTRBZBF)->ZBF_QTDVEN :=_nQtd
   (_cTRBZBF)->ZBF_UNSVEN :=_nQtd2
   (_cTRBZBF)->ZBF_VALOR  :=_nValorTot

ElseIf _cCampo == "TUDOOK_MANUT" // Validação total

   If !U_AOMS132Z("GRAVAR")
      _lRet := .F.
      Break
   EndIf

   // Carrega os itens da tabela ZBD para validação de Quantidades
   ZBD->(DBSetOrder(1))
   ZBD->(MsSeek(xFilial("ZBD")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL)))

   _aDadosValZBD:= {}
   _nTotPallet  := 0

   While ! ZBD->(Eof()) .And. ZBD->(ZBD_FILIAL+ZBD_PEDCOM+ZBD_CLIENT+ZBD_LOJACL) == xFilial("ZBD")+ZBC->(ZBC_PEDCOM+ZBC_CLIENT+ZBC_LOJACL)

      aAdd(_aDadosValZBD,{ZBD->ZBD_PEDCOM,;   // Pedido de Compras               // 01
                           ZBD->ZBD_ITEM  ,;   // Item                            // 02
                           ZBD->ZBD_PRODUT,;   // Codigo do Produto               // 03
                           AllTrim(ZBD->ZBD_DESCRI),;// Descrição do Produto      // 04
                           ZBD->ZBD_UNSVEN,;   // Qtd. Segunda Unidade Med.       // 05
                           ZBD->ZBD_SEGUM ,;   // Segunda Unidade Medida          // 06
                           ZBD->ZBD_QTDVEN,;   // Qtd. Primeira Unidade Medida    // 07
                           ZBD->ZBD_QTDPAL})   // Qtd. Primeira Unidade Medida    // 08
      ZBD->(DBSkip())
   EndDo

   (_cTRBZBF)->(DBSetOrder(2)) //ZBF_PEDCOM + ZBF_ITEM

   _aErros    :={}
   For _nI := 1 To Len(_aDadosValZBD)

         (_cTRBZBF)->(MsSeek(_aDadosValZBD[_nI,1]+_aDadosValZBD[_nI,2]))

         _nSomaPale := 0
         _nSomaQtd1 := 0
         _nSomaQtd2 := 0

         While ! (_cTRBZBF)->(Eof()) .And. (_cTRBZBF)->ZBF_PEDCOM + (_cTRBZBF)->ZBF_ITEM == _aDadosValZBD[_nI,1]+_aDadosValZBD[_nI,2]
            If (_cTRBZBF)->DELETED
               (_cTRBZBF)->(DBSkip())
               Loop
            EndIf

            _nSomaPale += (_cTRBZBF)->ZBF_QTDPAL
            _nSomaQtd1 += (_cTRBZBF)->ZBF_QTDVEN
            _nSomaQtd2 += (_cTRBZBF)->ZBF_UNSVEN
            _cErro:=""
            //             _cTrocaNf            , _cFilCarre          , _cFilFatur          ,_cTIPO     ,_lMostra,_cErro
            If !AOMS132Val((_cTRBZBF)->ZBF_TRCNF,(_cTRBZBF)->ZBF_FLFNC,(_cTRBZBF)->ZBF_FILFT,M->ZBC_TIPO,.F.     ,@_cErro)
               _lRet := .F.
            EndIf

            aAdd(_aErros,{Empty(_cErro)          ,;
                        (_cTRBZBF)->ZBF_AGRUPA ,;
                        (_cTRBZBF)->ZBF_SEQ    ,;
                        _aDadosValZBD[_nI,2]   ,;
                        _aDadosValZBD[_nI,3]   ,;
                        _aDadosValZBD[_nI,4]   ,;
                        Trans((_cTRBZBF)->WK_QTDPAL ,"@E 9,999.99") ,;//Original
                        Trans((_cTRBZBF)->WK_QTDVEN ,"@E 999,999,999.9999") ,;//Original
                        Trans((_cTRBZBF)->WK_UNSVEN ,"@E 999,999,999.9999") ,;//Original
                        Trans((_cTRBZBF)->ZBF_QTDPAL,"@E 9,999.99") ,;//Somados
                        Trans((_cTRBZBF)->ZBF_QTDVEN,"@E 999,999,999.9999") ,;//Somados
                        Trans((_cTRBZBF)->ZBF_UNSVEN,"@E 999,999,999.9999") ,;//Somados
                        (_cTRBZBF)->ZBF_TRCNF  ,;
                        (_cTRBZBF)->ZBF_FLFNC  ,;
                        (_cTRBZBF)->ZBF_FILFT  ,;
                        M->ZBC_TIPO            ,;
                        _cErro                 })

            (_cTRBZBF)->(DBSkip())
         EndDo

         If _nSomaQtd1 <>  _aDadosValZBD[_nI,7] .Or. _nSomaQtd2 <>  _aDadosValZBD[_nI,5] .Or. _nSomaPale <>  _aDadosValZBD[_nI,8]
            _cErro:='As quantidades SOMADAS para o item: '+AllTrim(_aDadosValZBD[_nI,2])+" - "+ AllTrim(_aDadosValZBD[_nI,3])+" - "+AllTrim(_aDadosValZBD[_nI,4])+;
                  ', é diferente das quantidades informadas no pedido de compras principal.'+;
                  "Valores: Soma 1UM: "+AllTrim(Trans(_nSomaQtd1,"@E 999,999,999.9999"))+" difere do Total 1UM: "+AllTrim(Trans(_aDadosValZBD[_nI,7],"@E 999,999,999.9999"))+;
                  " Soma 2UM: "+AllTrim(Trans(_nSomaQtd2,"@E 999,999,999.9999"))+" difere do Total 2UM: "+AllTrim(Trans(_aDadosValZBD[_nI,5],"@E 999,999,999.9999"))
            _lRet := .F.
         EndIf

         (_cTRBZBF)->(MsSeek(_aDadosValZBD[1,1]+_aDadosValZBD[1,2]))
         aAdd( _aErros , {Empty(_cErro)          ,;
                        "Total ITEM "+_aDadosValZBD[_nI,2] ,;
                        "  "                   ,;
                        "  "                   ,;
                        _aDadosValZBD[_nI,3]   ,;
                        _aDadosValZBD[_nI,4]   ,;
                        Trans(_aDadosValZBD[_nI,8] ,"@E 9,999.99") ,;
                        Trans(_aDadosValZBD[_nI,7] ,"@E 999,999,999.9999") ,;
                        Trans(_aDadosValZBD[_nI,5] ,"@E 999,999,999.9999") ,;
                        Trans(_nSomaPale ,"@E 9,999.99") ,;
                        Trans(_nSomaQtd1 ,"@E 999,999,999.9999") ,;
                        Trans(_nSomaQtd2 ,"@E 999,999,999.9999") ,;
                        " "                    ,;
                        " "                    ,;
                        " "                    ,;
                        " "                    ,;
                        _cErro                 })

   Next _nI

   If !_lRet .And. Len(_aErros) > 0
         _aTitulos:={""                                    ,;
                     GetSX3Cache("ZBF_AGRUPA","X3_TITULO") ,;
                     GetSX3Cache("ZBF_SEQ   ","X3_TITULO") ,;
                     GetSX3Cache("ZBF_ITEM  ","X3_TITULO") ,;
                     GetSX3Cache("ZBF_PRODUT","X3_TITULO") ,;
                     GetSX3Cache("ZBF_DESCRI","X3_TITULO") ,;
                     "Paletes Original" ,;
                     "Qtde 1m Original" ,;
                     "Qtde 2m Original" ,;
                     "Paletes Somada  " ,;
                     "Qtde 1m Somada  " ,;
                     "Qtde 2m Somada  " ,;
                     GetSX3Cache("ZBF_TRCNF ","X3_TITULO") ,;
                     GetSX3Cache("ZBF_FLFNC ","X3_TITULO") ,;
                     GetSX3Cache("ZBF_FILFT ","X3_TITULO") ,;
                     GetSX3Cache("ZBC_TIPO  ","X3_TITULO") ,;
                     "Inconcistencias                      "}

         U_ITListBox( 'Lista dos erros dos Pedidos do Cliente: '+ ZBC->ZBC_CLIENT+" "+ZBC->ZBC_LOJACL+" / PV: "+ZBC->ZBC_FILIAL+" "+ZBC->ZBC_PEDCOM,  _aTitulos , _aErros , .T. , 4 , )
   EndIf
   (_cTRBZBF)->(DBSetOrder(1))
   (_cTRBZBF)->(DBGoTop())
EndIf

End Sequence

(_cTRBZBF)->(DBGoTo(_nRegAtu))
_oGetTRBF:ForceRefresh()

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS132F
Autor-------------: Julio de Paula Paz
Data da Criacao---: 24/03/2022
Descrição---------: Rotina de Geração dos Pedidos de Vendas no Protheus. Gera SC5 e SC6.
Parametros--------: _aCab, _aDet, _aRecZBF, _cAgrupa, _cSequen
Retorno-----------: _lRet = .T. = Gerou pedido de vendas. /  .F. = Não gerou pedido de vendas.
===============================================================================================================================
*/
User Function AOMS132F(_aCab As array, _aDet As array, _aRecZBF As array, _cAgrupa As char,_cSequen As char) As logical

Local _nI               As numeric
Local _cPedOrigem       As char
Local cLogErro          As char
Local _lRet             As logical
Private lMsErroAuto     As logical
Private lAutoErrNoFile  As logical
Private lMsHelpAuto     As logical
Private _cAOMS074Vld    As char
Private _cAOMS074       As char
_lRet          := .T.
cLogErro       := ""
lAutoErrNoFile := .T.
lMsErroAuto    := .F.
lMsHelpAuto    := .T.
_cAOMS074Vld   := ""       //PEGA AS MENSAGENS DE ERRO DO MT410TOK.PRW
_cAOMS074      := "AOMS132"//NAO MOSTRA MENSAGENS DO MT410TOK.PRW

cFilAnt        := _aCab[_nColFilia,2]//INICIA NA FILIAL DE CARREGAMENTO
_nConta++
FWMsgRun( , {|| MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCab , _aDet, 3 ) }, "AGUARDE...", "Gerando Pedido: "+StrZero(_nConta,3)+", Pedidos com Erro: "+StrZero(_nPVnaoGer,3))

If lMSErroAuto
_nPVnaoGer++ //CONTA QUANTOS PEDIDOS NÃO FOI GERADO
If ( __lSx8 )
      RollBackSx8()
   EndIf
   aErroAuto  := GetAutoGRLog()
   For _nI := 1 To Len(aErroAuto)
      cLogErro += AllTrim(aErroAuto[_nI])+CRLF
   Next _nI
   cLogErro   := _cAOMS074Vld+" ["+cLogErro+"] "
   _cPedOrigem:=" "
   _lRet := .F.
ElseIf _lGerouPV
   cLogErro    := "Pedido de Vendas incluido com SUCESSO. Pedido de Vendas Numero: " + AllTrim(SC5->C5_NUM)+"."
   _cPedOrigem := SC5->C5_NUM
   For _nI := 1 To Len(_aRecZBF)
      ZBF->(DBGoTo(_aRecZBF[_nI]))
      ZBF->(RecLock("ZBF",.F.))
      ZBF->ZBF_PVPROT := _cPedOrigem
      ZBF->(MSUnLock())
   Next _nI
EndIf

aAdd(_aRetGer,{_lRet                 ,;//01
            _aCab[_nColFilia,2]    ,;//02
            _cPedOrigem            ,;//03
            _cAgrupa               ,;//04
            _cSequen               ,;//05
            _aCab[_nColAGEND,2]    ,;//06
            _aCab[_nColDTENT,2]    ,;//07
            _aCab[_nColTRCNF,2]    ,;//08
            _aCab[_nColFLFNC,2]    ,;//09
            _aCab[_nColFILFT,2]    ,;//10
            cLogErro               })//11

If !_lGerouPV//SE UM PEDIDO DEU ERRADO DESFAZ TODOS
   DisarmTransaction()
EndIf


Return _lRet
/*
===============================================================================================================================
Programa----------: AOMS132Val
Autor-------------: Alex Wallauer
Data da Criacao---: 28/11/2024
Descrição---------: Validacao da filiais de troca nota
Parametros--------: _cTrocaNf, _cFilCarre, _cFilFatur,_cTIPO,_lMostra,_cErro
Retorno-----------: _lRet = .T. = OK / .F. = NÃO VALIDOU
===============================================================================================================================
*/
Static Function AOMS132Val(_cTrocaNf As char,_cFilCarre As char,_cFilFatur As char,_cTIPO As char, _lMostra As logical, _cErro As char) As Logical

Local _lRet := .T.
Local _cFilAnt:=cFilAnt//SALVA ******

Default _lMostra := .T.
Default _cErro:=""

Begin Sequence//Não retirar

If _cTrocaNf = "N"
   If _cFilCarre <> _cFilFatur
      _lRet := .F.
      If _lMostra
         U_ITMsg("O pedido não é um pedido de vendas Troca Nota.",,'As filiais de faturamento e carregamento devem ser iguais',,,,.T.)
         Break
      Else
         _cErro+="O pedido não é um pedido de vendas Troca Nota. As filiais de faturamento e carregamento devem ser iguais"+CRLF
      EndIf
   EndIf

ElseIf _cTrocaNf = "S"

   If _cTIPO # "N"
      _lRet := .F.
      If _lMostra
         U_ITMsg("O pedido foi marcado como troca nota que só pode ser usado com Pedido do Tipo Normal",,'Altere o tipo do Pedido para "N"-Normal',,,,.T.)
         Break
      Else
         _cErro+='O pedido foi marcado como troca nota que só pode ser usado com Pedido do Tipo Normal. Altere o tipo do Pedido para "N"-Normal'+CRLF
      EndIf
   EndIf

   If !Empty(_cFilCarre+_cFilFatur) .And. _cFilCarre == _cFilFatur
      _lRet := .F.
      If _lMostra
         U_ITMsg("Filial de Faturamento não pode ser igual a de Carregamento",,"Altere a filial de Carregamento",,,,.T.)
         Break
      Else
         _cErro+="Filial de Faturamento não pode ser igual a de Carregamento. Altere a filial de Carregamento"+CRLF
      EndIf
   EndIf

   cFilAnt:=_cFilCarre
   If AllTrim(SuperGetMV("IT_PRONF",.F.,"N")) == "N" //Testa a Filial atual se pode ser troca nota
      _lRet := .F.
      If _lMostra
         U_ITMsg("Filial de carregamento não é de troca nota: "+cFilAnt,,"Verifique o Parametro: IT_PRONF.",,,,.T.)
         Break
      Else
         _cErro+="Filial de carregamento não é de troca nota: "+cFilAnt+". Verifique o Parametro: IT_PRONF."+CRLF
      EndIf
   EndIf

   cFilDes:= GetAdvFVal("ZZM","ZZM_DESCRI",xFilial("ZZM")+_cFilFatur,1,"")
   If Empty(_cFilFatur) .Or. Empty(cFilDes)//Testa se a filial de faturamento foi preenchida e existe no ZZM
      _lRet := .F.
      If _lMostra
         U_ITMsg("Filial de Faturamento nao preenchida ou nao Cadastrada: " +_cFilFatur,,"Preencha com uma filial cadastrada. (ZZM)",,,,.T.)
         Break
      Else
         _cErro+="Filial de Faturamento nao preenchida ou nao Cadastrada: " +_cFilFatur+". Preencha com uma filial cadastrada. (ZZM)"+CRLF
      EndIf
   EndIf

   cFilAnt:=_cFilFatur
   If AllTrim(SuperGetMV("IT_FATNF",.F.,"N")) == "N" //Testa a filial de Faturamento
      _lRet := .F.
      If _lMostra
         U_ITMsg("Filial de Faturamento não é de troca nota: "+_cFilFatur,,"Verifique o Parametro: IT_FATNF",,,,.T.)
         Break
      Else
         _cErro+="Filial de Faturamento não é de troca nota: "+_cFilFatur+". Verifique o Parametro: IT_FATNF"+CRLF
      EndIf
   EndIf

   cFilsFat:= AllTrim(GetAdvFVal("ZZM","ZZM_FILFAT",xFilial("ZZM")+_cFilCarre,1,""))
   If Empty(cFilsFat)//Testa se a filial de faturamento esta no grupo do campo ZZM
      _lRet := .F.
      If _lMostra
         U_ITMsg("Filial de Carregamento: "+_cFilCarre+" não possui grupo de Filiais de Faturamento",,;
                  "Entre em contato com a area de TI para cadastrar novas filiais no grupo no Configurador Italac \ Usuários \ Cad Filiais.",,,,.T.)
         Break
      Else
         _cErro+="Filial de Carregamento: "+_cFilCarre+" não possui grupo de Filiais de Faturamento. Entre em contato com a area de TI para cadastrar novas filiais no grupo no Configurador Italac \ Usuários \ Cad Filiais."+CRLF
      EndIf

   ElseIf !_cFilFatur $ cFilsFat//Testa se a filial de faturamento esta no grupo do campo ZZM
      _lRet := .F.
      If _lMostra
         U_ITMsg("Filial de Faturamento "+_cFilFatur+" nao esta no grupo de filiais ("+cFilsFat+") da Filial de Carregamento: "+_cFilCarre,,;
                  "Entre em contato com a area de TI para cadastrar novas filiais no grupo no Configurador Italac \ Usuários \ Cad Filiais.",,,,.T.)
         Break
      Else
         _cErro+="Filial de Faturamento "+_cFilFatur+" nao esta no grupo de filiais ("+cFilsFat+") da Filial de Carregamento: "+_cFilCarre+". Entre em contato com a area de TI para cadastrar novas filiais no grupo no Configurador Italac \ Usuários \ Cad Filiais."+CRLF
      EndIf
   EndIf

EndIf

End Sequence//Não retirar

cFilAnt:=_cFilAnt//VOLTA ******

Return _lRet

/*
===============================================================================================================================
Programa----------: AOM132Desm
Autor-------------: Alex Wallauer
Data da Criacao---: 13/12/2024
Descrição---------: Tela de Desmembramento de Quantidades
Parametros--------: nQtde
Retorno-----------: .T.
===============================================================================================================================
*/
Static Function AOM132Desm(nQtde) As logical

Local lGrava      As logical
Local _oDlg       As object
Local _nI         As numeric
Local _nSeq       As numeric
Local _nCol1      As numeric
Local _nLinha     As numeric
Local _nQtd2      As numeric
Local _nRecno     As numeric
Local _nQtdTPalet As numeric
Local _cCampo     As Char
Local _cCampoQt   As Char
Local _xCoteudo   As Char

Private _nQtdeTotal As numeric
Private _nQtdeAtual As numeric
Private _nQtdAPalet As numeric
Private _nQtdNPalet As numeric
Private _nQtdeNova  As numeric
Private _nDCXPalet  As numeric
Private _nQtdPalet  As numeric
Private _oQtdeAtual As object
Private _oPalAtual  As object
Private _oPalNova   As object
Private _cUMPal     As Char

_nRecno:=(_cTRBZBF)->(Recno())

For _nI := 1 To (_cTRBZBF)->(FCount())
   M->&((_cTRBZBF)->(FieldName(_nI))) := (_cTRBZBF)->(FieldGet(_nI))
Next _nI

_nSeq:=0
(_cTRBZBF)->(DBGoTop())
While !(_cTRBZBF)->(Eof())//NÃO IGNORAR O DELETED
   If Val((_cTRBZBF)->ZBF_SEQ) >= _nSeq
      _nSeq:=Val((_cTRBZBF)->ZBF_SEQ)+1
   EndIf
   (_cTRBZBF)->(DBSkip())
EndDo
(_cTRBZBF)->(DBGoTo(_nRecno))

If nQtde > 0
   M->ZBF_UNSVEN:=(M->ZBF_UNSVEN/nQtde)
   M->ZBF_QTDVEN:=(M->ZBF_QTDVEN/nQtde)
   M->ZBF_VALOR :=(M->ZBF_VALOR /nQtde)
   M->ZBF_QTDPAL:=(M->ZBF_QTDPAL/nQtde)
   (_cTRBZBF)->WK_UNSVEN :=M->ZBF_UNSVEN
   (_cTRBZBF)->WK_QTDVEN :=M->ZBF_QTDVEN
   (_cTRBZBF)->ZBF_UNSVEN:=M->ZBF_UNSVEN
   (_cTRBZBF)->ZBF_QTDVEN:=M->ZBF_QTDVEN
   (_cTRBZBF)->ZBF_VALOR :=M->ZBF_VALOR
   (_cTRBZBF)->ZBF_QTDPAL:=M->ZBF_QTDPAL
   lGrava:=.T.
Else

   _cCampoQt   := "ZBF_UNSVEN"
   _nQtdeTotal := (_cTRBZBF)->ZBF_UNSVEN
   _nQtdTPalet := (_cTRBZBF)->ZBF_QTDPAL
   _nQtdeAtual := _nQtdeTotal
   _nQtdAPalet := _nQtdTPalet
   _nQtdeNova  := 0

   _nDCXPalet:= 0  //Preenchido na rotina AOMS132CT ()
   _cUMPal   := "" //Preenchido na rotina AOMS132CT ()
   _cUMPal2UM:= "" //Preenchido na rotina AOMS132CT ()
   AOMS132CT((_cTRBZBF)->ZBF_PRODUT,0)
   If _nDCXPalet = 0
      U_ITMsg('A quantidades por palete não foi informada no cadastrado para este produto.',"Atenção","",1)
      Return .F.
   EndIf
   If !Empty(_cUMPal2UM)
      _cUMPal:=_cUMPal2UM
   EndIf

   While .T.

      lGrava    := .F.
      _nCol1    := 010
      _nLinha   := 005
      _nQtdNPalet:= 0

      DEFINE MSDIALOG _oDlg TITLE "Digite a quantidade da nova sequencia:" FROM 000,000 To 290,450 PIXEL

         @ _nLinha, _nCol1 Say "Produto com "+_cUMPal+" por Palete" OF _oDlg PIXEL
         _nLinha+=10

         @ _nLinha, _nCol1 Say "Quantidade do item total:"       OF _oDlg PIXEL
         _nLinha+=10

         @ _nLinha, _nCol1     MSGET _nQtdeTotal SIZE 99,11      OF _oDlg PIXEL Picture "@E 999,999,999.9999" WHEN .F.
         @ _nLinha, _nCol1+100 MSGET _nQtdTPalet SIZE 50,11      OF _oDlg PIXEL Picture "@E 9,999.99"            WHEN .F.
         _nLinha+=03
         @ _nLinha, _nCol1+150 Say "Paletes"                     OF _oDlg PIXEL
         _nLinha+=20

         @ _nLinha, _nCol1 Say "Quantidade do item posicionado: "+(_cTRBZBF)->ZBF_SEQ+" "+AllTrim((_cTRBZBF)->ZBF_AGRUPA) OF _oDlg PIXEL
         _nLinha+=10

         @ _nLinha, _nCol1     MSGET _oQtdeAtual VAR _nQtdeAtual SIZE 99,11 OF _oDlg PIXEL Picture "@E 999,999,999.9999" WHEN .F.
         @ _nLinha, _nCol1+100 MSGET _oPalAtual  VAR _nQtdAPalet SIZE 50,11 OF _oDlg PIXEL Picture "@E 9,999.999" WHEN .F.
         _nLinha+=03
         @ _nLinha, _nCol1+150 Say "Paletes"                                OF _oDlg PIXEL
         _nLinha+=20

         @ _nLinha, _nCol1 Say "Quantidade da nova sequencia:"+StrZero(_nSeq,3) OF _oDlg PIXEL
         _nLinha+=10

         @ _nLinha, _nCol1     MSGET _nQtdeNova                SIZE 99,11 OF _oDlg PIXEL   Picture "@E 999,999,999.9999" VALID U_AOMS132V("#QUANTIDADE")
         @ _nLinha, _nCol1+100 MSGET _oPalNova VAR _nQtdNPalet SIZE 50,11 OF _oDlg PIXEL   Picture "@E 9,999.999" WHEN .F.
         _nLinha+=03
         @ _nLinha, _nCol1+150 Say "Paletes"                              OF _oDlg PIXEL
         _nLinha+=20

         DEFINE SBUTTON FROM _nLinha,_nCol1       Type 1 ACTION (lGrava:=.T.,_oDlg:End()) ENABLE OF _oDlg
         DEFINE SBUTTON FROM _nLinha,(_nCol1+55)  Type 2 ACTION (lGrava:=.F.,_oDlg:End()) ENABLE OF _oDlg

      Activate MSDialog _oDlg Centered

      If lGrava

         If _nQtdeTotal = 0 .Or. _nQtdeAtual = 0
            Loop
         EndIf

         If _nQtdeAtual <= 0
            U_ITMsg('A quantidade do item posicionado na primeira unidade de medida tem que ser maior que zero.',"Atenção","",1)
            Loop
         EndIf
         If _nQtdeNova <= 0
            U_ITMsg('O preenchimento da quantidade da nova sequencia unidade de medida é obrigatório.',"Atenção","",1)
            Loop
         EndIf
         If (_nQtdeNova + _nQtdeAtual) <> _nQtdeTotal
            U_ITMsg('A soma das quantidades difere da quantidade total.',"Atenção","",1)
            Loop
         EndIf

         If _cCampoQt == "ZBF_UNSVEN"  // QUANTIDADE SEGUNDA UNIDADE #UNSVEN

            ////////////////   "QUANTIDADE DA NOVA SEQUENCIA:"  /////////////////////////////////
            _nQtd2    := _nQtdeNova
            _nQtd1    := AOMS132CNV(_nQtd2, 2 , 1,(_cTRBZBF)->ZBF_PRODUT)
            _cUMPal   := "" //Preenchido na rotina AOMS132CT ()
            _cUMPal2UM:= "" //Preenchido na rotina AOMS132CT ()
            _nQtdNPalet := AOMS132CT((_cTRBZBF)->ZBF_PRODUT,_nQtd1)  //CALCULO DA QUANTIDADE DE PALETES
            If !Empty(_cUMPal2UM)
               _cUMPal:=_cUMPal2UM
            EndIf
            If _nQtdNPalet <> Int(_nQtdNPalet)
               U_ITMsg('A quantidade informada na segunda unidade de medida não é multipla das quantidades por palete para este item. '+ _cUMPal+" por palete.","Atenção","",1)
               Loop
            EndIf

            M->WK_QTDVEN  := _nQtd1
            M->ZBF_QTDVEN := _nQtd1
            M->WK_UNSVEN  := _nQtd2
            M->ZBF_UNSVEN := _nQtd2
            M->ZBF_QTDPAL := _nQtdNPalet
            M->ZBF_VALOR  := ((_cTRBZBF)->ZBF_PRCVEN * _nQtd1)

            ////////////////   "QUANTIDADE DO ITEM POSICIONADO:"  /////////////////////
            _nQtd2    := _nQtdeAtual
            _nQtd1    := AOMS132CNV(_nQtd2, 2 , 1,(_cTRBZBF)->ZBF_PRODUT)
            _cUMPal   := "" //Preenchido na rotina AOMS132CT ()
            _cUMPal2UM:= "" //Preenchido na rotina AOMS132CT ()
            _nQtdNPalet := AOMS132CT((_cTRBZBF)->ZBF_PRODUT,_nQtd1)  //CALCULO DA QUANTIDADE DE PALETES
            If !Empty(_cUMPal2UM)
               _cUMPal:=_cUMPal2UM
            EndIf
            If _nQtdNPalet <> Int(_nQtdNPalet)
               U_ITMsg('A quantidade informada na segunda unidade de medida não é multipla das quantidades por palete para este item. '+ _cUMPal +" por palete.","Atenção","",1)
               Loop
            EndIf
            //GRAVA A LINHA ATUAL
            (_cTRBZBF)->WK_QTDVEN  := _nQtd1
            (_cTRBZBF)->ZBF_QTDVEN := _nQtd1
            (_cTRBZBF)->WK_UNSVEN  := _nQtd2
            (_cTRBZBF)->ZBF_UNSVEN := _nQtd2
            (_cTRBZBF)->ZBF_QTDPAL := _nQtdNPalet
            (_cTRBZBF)->ZBF_VALOR  := ((_cTRBZBF)->ZBF_PRCVEN * _nQtd1)
         EndIf
      EndIf
      Exit
   EndDo
EndIf

If lGrava

   (_cTRBZBF)->(DbAppend())//GRAVA A NOVA LINHA
   For _nI := 1 To (_cTRBZBF)->(FCount())
      _cCampo:=(_cTRBZBF)->(FieldName(_nI))
      _xCoteudo:=M->&(_cCampo)
      (_cTRBZBF)->(FieldPut( _nI , _xCoteudo ) )
   Next _nI

   (_cTRBZBF)->ZBF_AGRUPA:= " "
   (_cTRBZBF)->ZBF_SEQ   := StrZero(_nSeq,3)
   (_cTRBZBF)->WK_RECNO  := 0//TEM QUE COLOCAR 0 POR QUE CONTROLA NA GRAVAÇÃO

Else
   (_cTRBZBF)->(DBGoTo(_nRecno))
EndIf

Return lGrava

/*
===============================================================================================================================
Programa----------: AOMS132CT
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 02/01/2025
Descrição---------: Retorna a Quantidade de Pallets - Cópia da MOMS66CT()
Parametros--------: _cProduto: COD. PRODUTO , _nQtde: 1 UM , _lRet1UM: Retorna a quantidade em 1 UM
Retorno-----------: _nQtPalete: Quantidade de Pallets
===============================================================================================================================
*/
Static Function AOMS132CT(_cProduto As Char ,_nQtde As Numeric, _lRet1UM ) As Numeric

Local _nQtPalete:=0 As Numeric
Default _lRet1UM := .F. //Se não For informado assume que não retorna a quantidade em 1 UM

//A ordem foi setada no inicio do programa
If !SB1->(DBSeek(xFilial()+_cProduto))
   Return 0
EndIf
_nDCXPalet:=SB1->B1_I_CXPAL//DECLARADA ANTES DA FUNCAO

// *** CALCULO DA QUANTIDADE EM 1 UM ***
If _lRet1UM

   _nQtPalete:=_nQtde

   If SB1->B1_I_UMPAL == '1'
      _nQtde	:= ( _nQtPalete * SB1->B1_I_CXPAL )//1 UM
   ElseIf SB1->B1_I_UMPAL == '2'
      _nQtde2um := (_nQtPalete * SB1->B1_I_CXPAL )//2 UM
      _nQtde    := AOMS132CNV( _nQtde2um , 2 , 1 )//1 UM
   ElseIf SB1->B1_I_UMPAL == '3'//ATE ENTÃO NÃO TEM NEHUM PRODUTO COM ESSA CONDIÇÃO
      _nQtde3UM := (_nQtPalete * SB1->B1_I_CXPAL )//3 UM
      _nQtde    := AOMS132CNV( _nQtde3UM , 3 , 1 )//1 UM
   EndIf

   Return _nQtde // *** RETORNA A QUANTIDADE NA 1 UM ***

   // *** CALCULO DA QUANTIDADE DE PALETES ***
   ElseIf SB1->B1_I_UMPAL == '1'
         _nQtPalete	:= ( _nQtde / SB1->B1_I_CXPAL )//1 UM
         _cUMPal:= AllTrim(TRANS(SB1->B1_I_CXPAL,"@E 9,999.99")) +' '+SB1->B1_UM
         _nQtde2UM:=AOMS132CNV( SB1->B1_I_CXPAL , 1 , 2 ) //1 UM Achou em 2 UM
         _cUMPal2UM:=AllTrim(TRANS(_nQtde2UM    ,"@E 9,999.99")) +' '+SB1->B1_SEGUM //DECLARADA ANTES DA FUNCAO

   ElseIf SB1->B1_I_UMPAL == '2'
      _nQtde2   := AOMS132CNV( _nQtde , 1 , 2 )//2 UM
      _nQtPalete:= (_nQtde2 / SB1->B1_I_CXPAL )
      _cUMPal   := AllTrim(TRANS(SB1->B1_I_CXPAL,"@E 9,999.99")) +' '+SB1->B1_SEGUM//DECLARADA ANTES DA FUNCAO
      _nQtde1UM :=AOMS132CNV( SB1->B1_I_CXPAL , 2 , 1 ) //1 UM
      _cUMPal1UM:=AllTrim(TRANS(_nQtde1UM      ,"@E 9,999.99")) +' '+SB1->B1_UM//DECLARADA ANTES DA FUNCAO

   ElseIf SB1->B1_I_UMPAL == '3'//ATE ENTÃO NÃO TEM NEHUM PRODUTO COM ESSA CONDIÇÃO
      _nQtde    := AOMS132CNV( _nQtde , 1 , 3 )//3 UM
      _nQtPalete:= (_nQtde  / SB1->B1_I_CXPAL )
      _cUMPal   := AllTrim(TRANS(SB1->B1_I_CXPAL,"@E 9,999.99")) +' '+SB1->B1_I_3UM//DECLARADA ANTES DA FUNCAO

   Else
      _cUMPal:= ''
      _nQtPalete:= 0
EndIf

Return _nQtPalete

/*
===============================================================================================================================
Programa----------: AOMS132CNV
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 02/01/2025
Descrição---------: Função para conversão entre unidades de medida - COPIA DA MOMS66CNV()
Parametros--------: _nQtdAux  As Numeric 
                    _nUMOri   As Numeric 
                    _nUMDes   As Numeric 
                    _cProduto As Char
Retorno-----------: _nRet: Resultado da conversão
===============================================================================================================================
*/
Static Function AOMS132CNV( _nQtdAux As Numeric, _nUMOri As Numeric, _nUMDes As Numeric, _cProduto As Char ) As Numeric

Local _nRet  := 0 As Numeric
Local _nfator:= 0 As Numeric
Default _cProduto:= SB1->B1_COD//Para quando o produto já esta posicionado 

//A ordem foi setada no inicio do programa
If _cProduto <> SB1->B1_COD .And. !SB1->(DBSeek(xFilial()+_cProduto))
   Return 0
EndIf

_nfator:=SB1->B1_CONV
If _nfator = 0
   If SB1->B1_I_QQUEI == 'S' .And. SB1->B1_I_FATCO > 0
      _nfator := SB1->B1_I_FATCO
   EndIf
EndIf
If _nfator = 0
   U_ITMsg('Fator de conversão da 1UM e 2UM zerado (B1_CONV e B1_I_FATCO).',"Atenção","Entre em contato com a TI.",1)
   Return 0
EndIf

Do Case
   Case _nUMDes == 1
      //================================================================================
      // Conversão da Segunda UM para a Primeira
      //================================================================================
      If _nUMOri == 2
         If SB1->B1_TIPCONV == 'D'
               _nRet := _nQtdAux * _nfator
         ElseIf SB1->B1_TIPCONV == 'M'
               _nRet := _nQtdAux / _nfator
         EndIf

         //================================================================================
         // Conversão da Terceira UM para a Primeira
         //================================================================================
      ElseIf _nUMOri == 3
         _nRet := _nQtdAux * SB1->B1_I_QT3UM
      EndIf

   Case _nUMDes == 2
      //================================================================================
      // Conversão da Primeira UM para a Segunda
      //================================================================================
      If _nUMOri == 1
         If SB1->B1_TIPCONV == 'D'
               _nRet := _nQtdAux / _nfator
         ElseIf SB1->B1_TIPCONV == 'M'
               _nRet := _nQtdAux * _nfator
         EndIf

         //================================================================================
         // Conversão da Terceira UM para a Segunda
         //================================================================================
      ElseIf _nUMOri == 3
         _nRet := _nQtdAux * SB1->B1_I_QT3UM

         If SB1->B1_TIPCONV == 'D'
               _nRet := _nRet / _nfator
         ElseIf SB1->B1_TIPCONV == 'M'
               _nRet := _nRet * _nfator
         EndIf
      EndIf

   Case _nUMDes == 3

      //================================================================================
      // Conversão da Primeira UM para a Terceira
      //================================================================================
      If _nUMOri == 1
         _nRet := _nQtdAux / SB1->B1_I_QT3UM

         //================================================================================
         // Conversão da Segunda UM para a Terceira
         //================================================================================
      ElseIf _nUMOri == 2
         If SB1->B1_TIPCONV == 'D'
               _nRet := _nQtdAux * _nfator
         ElseIf SB1->B1_TIPCONV == 'M'
               _nRet := _nQtdAux / _nfator
         EndIf

         _nRet := _nRet / SB1->B1_I_QT3UM
      EndIf
   EndCase

Return( _nRet )
