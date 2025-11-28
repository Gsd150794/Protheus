/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |23/07/2025| Chamado 51085. Ajustes para reversão das alterações posteriores ao chamado 50527.
Lucas Borges  |24/07/2025| Chamado 51340. Ajustar função para validação de ambiente de teste
Igor Melgaço  |26/08/2025| Chamado 47930. Ajustes para inclusão das alterações posteriores ao chamado 50527.
===============================================================================================================================
*/

#Include "FWMVCDEF.CH"
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AFIN037
Autor-------------: Igor Melgaço
Data da Criacao---: 31/03/2025
Descrição---------: Aprovação de Prorogações de Vencimento. Chamado: 47833 
Parametros--------: 
Retorno-----------:  
===============================================================================================================================
*/ 
User Function AFIN037(_lFiltra) As Logical
Local _oBrowse := Nil As Object
Local _cAprov := SuperGetMV("IT_AFIN037",.F., "002355") As Char

Default _lFiltra := .F.

If !Empty(_cAprov) .And. RetCodUsr() $ _cAprov
   _oBrowse := FWMBrowse():New()
   _oBrowse:SetAlias("ZM4")
   _oBrowse:SetMenuDef( 'AFIN037' )
   _oBrowse:SetDescription("Aprovação de Prorogações de Vencimento")

   _oBrowse:AddLegend( "ZM4_STATUS=='N'", "GREEN"      ,"Nao Aprovado")
   _oBrowse:AddLegend( "ZM4_STATUS=='A'", "RED"        ,"Aprovado")
   _oBrowse:AddLegend( "ZM4_STATUS=='R'", "BLACK"      ,"Rejeitado")

   If _lFiltra
      _oBrowse:SetFilterDefault( "ZM4->ZM4_STATUS=='N'") 
   EndIf

   _oBrowse:Activate()
Else
	  U_ITMsg("Usuário sem permissão para aprovação de prorrogação de títulos!"					,;
				"Atenção!"																						,;
				"Comunique o administrador do sistema.",1)

EndIf

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Igor Melgaço
Data da Criacao---: 24/07/2024
Descrição---------: Rotina de definição automática do menu via MVC
Parametros--------: 
Retorno-----------: aRotina - Definições do menu principal da Rotina.
===============================================================================================================================
*/
Static Function MenuDef() As Array
Local _aRotina := {} As Array

ADD OPTION _aRotina Title 'Aprovar'                    Action 'U_AFIN037R()'    	OPERATION 4 ACCESS 0
ADD OPTION _aRotina Title 'Rejeitar'                   Action 'VIEWDEF.AFIN037' 	OPERATION 4 ACCESS 0
ADD OPTION _aRotina Title 'Visualizar'	                Action 'VIEWDEF.AFIN037'	OPERATION 2 ACCESS 0

Return( _aRotina )

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Igor Melgaço
Data da Criacao---: 24/07/2024
Descrição---------: Rotina de definição do Modelo de Dados do MVC
Parametros--------: 
Retorno-----------: _oModel - Objeto do modelo de dados do MVC 
===============================================================================================================================
*/ 
Static Function ModelDef() As Array
Local _oStruZM4 := FWFormStruct(1,"ZM4") As Object
Local _oStruSE1 := FWFormStruct(1,'SE1',{|x| AllTrim(x) $ "|E1_FILIAL|E1_NUM|E1_PREFIXO|E1_PARCELA|E1_TIPO|E1_CLIENTE|E1_LOJA|E1_NOMCLI|E1_VENCTO|E1_VENCREA|E1_EMISSAO|E1_SALDO"}) As Object
Local _oModel As Object
Local _aSE1Rel := {} As Array
Local _bCommit := {|_oModel| U_AFIN037O(_oModel)} As Block


_oStruSE1:AddField( ;
        AllTrim('Saldo') , ;             // [01] C Titulo do campo
        AllTrim('') , ;             // [02] C ToolTip do campo
        'E1_SALDO_' , ;            // [03] C identificador (ID) do Field
        'N' , ;                     // [04] C Tipo do campo
        15 , ;                      // [05] N Tamanho do campo
        2 , ;                       // [06] N Decimal do campo
        NIL , ;                     // [07] B Code-block de validação do campo
        NIL , ;                     // [08] B Code-block de validação When do campo
        NIL , ;                     // [09] A Lista de valores permitido do campo
        NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
        { || SE1->E1_SALDO } , ;       // [11] B Code-block de inicializacao do campo
        NIL , ;                     // [12] L Indica se trata de um campo chave
        NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
        .T. )                       // [14] L Indica se o campo é virtual 


_oModel := MPFormModel():New('AFIN037M' ,   /*bPreValidacao*/ , /*_bPosValidacao*/ , _bCommit /*bCommit*/ , /*bCancel*/)

_oModel:AddFields('ZM4CAB', /*cOwner*/ ,_oStruZM4,/*bPreValidacao*/ , /*_bPosValidacao*/ , /*bCarga*/)

_oModel:AddGrid('SE1DETAIL','ZM4CAB',_oStruSE1,/*bLinePre*/, /*bLinePost*/, /*bPreVal*/,/*bPosVal*/, /*bLoad*/)

aAdd(_aSE1Rel, {'E1_FILIAL' , 'ZM4CAB.ZM4_FILIAL'} )
aAdd(_aSE1Rel, {'E1_NUM'    , 'ZM4CAB.ZM4_DOC'})
aAdd(_aSE1Rel, {'E1_PREFIXO', 'ZM4CAB.ZM4_SERIE'})
aAdd(_aSE1Rel, {'E1_TIPO'   , 'ZM4CAB.ZM4_TIPO'})

_oModel:SetRelation('SE1DETAIL', _aSE1Rel, SE1->(IndexKey(1)))

_oModel:GetModel('SE1DETAIL'):SetNoInsertLine( .T. )
_oModel:GetModel('SE1DETAIL'):SetNoDeleteLine( .T. )
_oModel:GetModel('SE1DETAIL'):SetNoUpdateLine( .T. )
_oModel:GetModel('SE1DETAIL'):SetOptional(.T.)
_oModel:GetModel('SE1DETAIL'):SetOnlyQuery(.T.)
_oModel:GetModel('SE1DETAIL'):SetOnlyView(.T.) 

_oModel:SetPrimaryKey( {'ZM4_FILIAL','ZM4_DOC','ZM4_SERIE','ZM4_CODIGO' } )
_oModel:SetDescription("Aprovações de Prorrogação de Vencto")
_oModel:SetVldActivate({|_oModel|   U_AFIN037B(_oModel)  })
_oModel:SetActivate({|_oModel| FWMsgRun( ,{||  U_AFIN037A(_oModel) } , "Carregando as grids de cadastro, Aguarde...",  ) })

Return _oModel

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Igor Melgaço
Data da Criacao---: 24/07/2024
Descrição---------: Rotina de definição da View do MVC
Parametros--------: 
Retorno-----------: _oView - Objeto de exibição do MVC  
===============================================================================================================================
*/ 
Static Function ViewDef() As Array
Local _oStruZM4 := FWFormStruct(2,"ZM4") As Object
Local _oStruSE1 := FWFormStruct(2,'SE1',{|x| AllTrim(x) $ "|E1_FILIAL|E1_NUM|E1_PREFIXO|E1_PARCELA|E1_TIPO|E1_CLIENTE|E1_LOJA|E1_NOMCLI|E1_VENCTO|E1_VENCREA|E1_EMISSAO|E1_SALDO"}) As Object

Local _oModel := FWLoadModel("AFIN037") As Object
Local _oView := Nil As Object

    _oStruSE1:AddField( ;                       // Ord. Tipo Desc.
        'E1_SALDO_'                     , ;     // [01] C   Nome do Campo
        "50"                            , ;     // [02] C   Ordem
        AllTrim( 'Saldo' )              , ;     // [03] C   Titulo do campo
        AllTrim( 'Saldo' )              , ;     // [04] C   Descricao do campo
        { }                             , ;     // [05] A   Array com Help
        'N'                             , ;     // [06] C   Tipo do campo
        "@E 9,999,999,999.99"           , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        .F.                             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .F.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 
 

 If FWIsInCallStack("U_AFIN037R") 
   _oStruZM4:RemoveField( 'ZM4_MOTREJ' )
 EndIf

_oView := FWFormView():New()
_oView:SetModel(_oModel)

// Configura as estruturas de modelo de dados
_oView:AddField("VIEW_ZM4",_oStruZM4,"ZM4CAB"   ,,)
_oView:AddGrid('VIEW_SE1' ,_oStruSE1,'SE1DETAIL',,)

//Setando o dimensionamento de tamanho
_oView:CreateHorizontalBox('CABEC',40)
_oView:CreateHorizontalBox('DETAIL',60)

//Amarrando a view com as box
_oView:SetOwnerView('VIEW_ZM4','CABEC')
_oView:SetOwnerView('VIEW_SE1','DETAIL')

//Habilitando título
_oView:EnableTitleView('VIEW_ZM4','Dados de Aprovação')
_oView:EnableTitleView('VIEW_SE1','Titulos do Documento')

_oView:SetViewProperty("VIEW_SE1", "GRIDSEEK", {.F.})
_oView:SetViewProperty("VIEW_SE1", "GRIDFILTER", {.F.}) 

_oView:SetCloseOnOk({||.T.})

Return _oView


/*
===============================================================================================================================
Programa----------: AFIN037O
Autor-------------: Igor Melgaço
Data da Criacao---: 24/07/2024
Descrição---------: Complementar a gravação de dados.
Parametros--------: _oModel = Modelo de dados.
Retorno-----------: _lRet = .T. 
===============================================================================================================================
*/
User Function AFIN037O(_oModel) As Logical
Local _oModelMaster := _oModel:GetModel("ZM4CAB") As Object
Local _nOperation   := _oModel:GetOperation() As Numeric
Local _nProrrogados := 0 As Numeric
Local _nSemSaldo := 0 As Numeric
Local _lRet := .F. As Logical
Local _nTit := 0 As Numeric
Local _aLog := {} As Array
Local _cCodOcorr := "" As Char
Local _lRejeitar := !(FWIsInCallStack("U_AFIN037R")) As Logical
Local cEmail := "" As Char
Local cNomeVend := "" As Char
Local cCordenador := "" As Char
Local cGerente := "" As Char
Local _cVend1 := "" As Char
Local _cCliente := "" As Char
Local _cLoja := "" As Char
Local _lRejeitado := .F. As Logical
Local _aButtons := {} As Array
Local _dVencAtu := CTOD("") As Date
Local _dProrog :=  CTOD("") As Date
Local _aBoletos := {} As Array
Local cFilePrint := "" As Char

Begin Transaction 

   //FWFormCommit(_oModel)//Grava o que esta no model
   
   _cFilial := xFilial("SE1")
   _cDoc    := _oModelMaster:GetValue("ZM4_DOC")
   _cSerie  := _oModelMaster:GetValue("ZM4_SERIE")
                           
   _cTipo   := SUPERGETMV('IT_TIPTITF',.F.,"NF/ICM") // _oModelMaster:GetValue("ZM4_TIPO") // Tipo do Título Financeiro. Ex: NF, ICM.
   
   _cCodigo := _oModelMaster:GetValue("ZM4_CODIGO")
   _nDias   := _oModelMaster:GetValue("ZM4_DPRORR")

   _oModelMaster:LoadValue("ZM4_APROV" ,Space(6))
   _oModelMaster:LoadValue("ZM4_NAPROV",Space(50))

   _oModelMaster:LoadValue("ZM4_APROV" ,RetCodUsr())
   _oModelMaster:LoadValue("ZM4_NAPROV",UsrFullName(RetCodUsr()))

   If _nOperation == MODEL_OPERATION_UPDATE
      If _lRejeitar
         //DBSelectArea("SE1")
         SE1->(DBSetOrder(1))
         If SE1->(MsSeek(_cFilial + _cSerie + _cDoc))
            _cCliente := SE1->E1_CLIENTE
            _cLoja    := SE1->E1_LOJA
            _cVend1   := SE1->E1_VEND1
         Else
            //DBSelectArea("SF2")
            SF2->(DBSetOrder(1))
            If SF2->(MsSeek(_cFilial + _cDoc ))
               _cCliente := SF2->F2_CLIENTE
               _cLoja    := SF2->F2_LOJA
               _cVend1   := SF2->F2_VEND1
            EndIf 
         EndIf
         _cMotivo := _oModelMaster:GetValue("ZM4_MOTREJ")
         
         //DBSelectArea("ZM4")
         ZM4->(RecLock("ZM4",.F.))
         ZM4->ZM4_APROV  := RetCodUsr()
         ZM4->ZM4_DTAPRO := Date()
         ZM4->ZM4_STATUS := "R"
         ZM4->ZM4_MOTREJ := _cMotivo
         ZM4->(MSUnLock())

         _lRet := .T.
      Else
         _aBoletos := {}
         _cMotivo := ""
         //DBSelectArea("SE1")
         SE1->(DBSetOrder(31)) // E1_FILIAL+E1_NUM+E1_SERIE+E1_CLIENTE+E1_LOJA
         If SE1->(MsSeek(_cFilial + _cDoc))
            While ! SE1->(Eof()) .And. _cFilial + _cDoc == SE1->(E1_FILIAL + E1_NUM )  //_cFilial + _cSerie + _cDoc + _cTipo == SE1->(E1_FILIAL + E1_PREFIXO + E1_NUM + E1_TIPO) .And. SE1->(!Eof())

               cFilePrint := ""

               If ! AllTrim(SE1->E1_TIPO) $ _cTipo // NF OU ICM.
                  SE1->(DBSkip())   
                  Loop
               EndIf 

               If AllTrim(SE1->E1_TIPO) == 'NF' .And. _cSerie <> SE1->E1_PREFIXO // Não dá para inserir esta condição no While. Para tipo = ICM, E1_PREFIXO = DCT.
                  SE1->(DBSkip())   
                  Loop
               EndIf 

               _nTit++
               If SE1->E1_SALDO > 0

                  _dVencAtu := SE1->E1_VENCTO
                  _dProrog :=  DataValida((SE1->E1_VENCTO) + _nDias,.T.)
                  
                  aVetSE1 := {}
                  aAdd(aVetSE1, {"E1_FILIAL" , SE1->E1_FILIAL           , Nil})
                  aAdd(aVetSE1, {"E1_NUM"    , SE1->E1_NUM              , Nil})
                  aAdd(aVetSE1, {"E1_PREFIXO", SE1->E1_PREFIXO          , Nil})
                  aAdd(aVetSE1, {"E1_PARCELA", SE1->E1_PARCELA          , Nil})
                  aAdd(aVetSE1, {"E1_TIPO"   , SE1->E1_TIPO             , Nil})
                  aAdd(aVetSE1, {"E1_CLIENTE", SE1->E1_CLIENTE          , Nil})
                  aAdd(aVetSE1, {"E1_LOJA"   , SE1->E1_LOJA             , Nil})
                  aAdd(aVetSE1, {"E1_I_DTPRO", _dProrog , Nil})
                  aAdd(aVetSE1, {"E1_I_PRORR", "S"                      , Nil})
                  aAdd(aVetSE1, {"E1_I_MTPRO", "Alterado por Ocorrencia de Frete" , Nil})
                  aAdd(aVetSE1, {"E1_VEND1"  , SE1->E1_VEND1            , Nil})
                  aAdd(aVetSE1, {"E1_VEND2"  , SE1->E1_VEND2            , Nil})
                  aAdd(aVetSE1, {"E1_VEND3"  , SE1->E1_VEND3            , Nil})
                  aAdd(aVetSE1, {"E1_VEND4"  , SE1->E1_VEND4            , Nil})
                  aAdd(aVetSE1, {"E1_VEND5"  , SE1->E1_VEND5            , Nil})
                  
                  lMsErroAuto := .F.
                  
                  MSExecAuto({|x,y| FINA040(x,y)}, aVetSE1, 4) // Alteração

                  //Se houve erro, mostra o erro ao usuário e desarma a transação
                  If lMsErroAuto
                     _lLog := .F.
                     _cLog := " Falha na Prorrogação do Titulo! " 
      					_cLog := " MSExecAuto:  "+AllTrim(MostraErro(Upper(GetSrvProfString("STARTPATH","")),"AFIN037.LOG"))+" "
                     //Help(NIL, NIL, "HELP", NIL, _cErro, 1, 0, NIL, NIL, NIL, NIL, NIL, {})

                     //MostraErro()
                     //Help(" ",1,"AFIN037",,_cErro,1,0)
                     //DisarmTransaction()
                  
                  Else
                     _cLog := "Titulo prorrogado com sucesso!"
                     _lLog := .T.

                     _nProrrogados++

                     _cSeq := U_AFIN034GNU()

                     //DBSelectArea("ZAC")
                     ZAC->(DBSetOrder(1))

                     ZAC->(RecLock("ZAC",.T.))
                     
                     ZAC->ZAC_FILIAL := SE1->E1_FILIAL
                     ZAC->ZAC_PREFIX := SE1->E1_PREFIXO 
                     ZAC->ZAC_NUM    := SE1->E1_NUM
                     ZAC->ZAC_TIPO   := SE1->E1_TIPO 
                     ZAC->ZAC_SEQ    := _cSeq
                     ZAC->ZAC_DATA   := Date()
                     ZAC->ZAC_HORA   := Time()
                     ZAC->ZAC_DESC   := ("Prorrogação de Vecto "+ IIf(!Empty(AllTrim(SE1->E1_PARCELA)),"da Parcela "+AllTrim(SE1->E1_PARCELA),"")+" para "+DToC(_dProrog)+" - Oriundo Ocorrência de Frete. Solicitante: " + AllTrim(UsrFullName(ZM4->ZM4_SOLICI)))
                     
                     ZAC->(MSUnLock())

                     _cCodOcorr := ""

                     If SE1->E1_PORTADO $ "001|341"
                        _cCodOcorr := "06"
                        _cDescOcorr := "ALTERACAO DE VENCIMENTO"
                     ElseIf SE1->E1_PORTADO == "237"
                        _cCodOcorr := "31"
                        _cDescOcorr := "ALTERACAO DE OUTROS DADOS"
                     EndIf

                     If !Empty(AllTrim(_cCodOcorr))
                        _dNovoVencto := SE1->E1_VENCTO

                        //ADICAO DA INCLUSÃO DA INSTRUCAO BANCARIA
                        FI2->(RecLock("FI2",.T.))

                        FI2->FI2_FILIAL := SE1->E1_FILIAL
                        FI2->FI2_OCORR  := _cCodOcorr
                        FI2->FI2_DESCOC := _cDescOcorr
                        FI2->FI2_PREFIX := SE1->E1_PREFIXO
                        FI2->FI2_TITULO := SE1->E1_NUM
                        FI2->FI2_PARCEL := SE1->E1_PARCELA
                        FI2->FI2_TIPO 	 := SE1->E1_TIPO
                        FI2->FI2_CODCLI := SE1->E1_CLIENTE
                        FI2->FI2_LOJCLI := SE1->E1_LOJA
                        FI2->FI2_GERADO := "2"
                        FI2->FI2_NUMBOR := SE1->E1_NUMBOR
                        FI2->FI2_CARTEI := "1"
                        FI2->FI2_DTOCOR := dDataBase
                        FI2->FI2_VALANT := DToC(_dVencAtu)
                        FI2->FI2_VALNOV := DToC(_dNovoVencto)
                        FI2->FI2_CAMPO  := "E1_VENCTO"
                        FI2->FI2_TIPCPO := "D"

                        FI2->(MSUnLock())

                     EndIf

                     cFilePrint := U_RFIN002P() // Gera o boleto para o cliente.
                  EndIf
               Else
                  _nSemSaldo++
                  _lLog := .F.
                  _cLog := "Falha na Prorrogação do Titulo. Título sem saldo para prorrogação. " 
               EndIf
               
               aAdd(_aBoletos,cFilePrint)

               aAdd(_aLog,{_lLog,SE1->E1_FILIAL,SE1->E1_NUM,SE1->E1_PREFIXO,SE1->E1_TIPO,SE1->E1_PARCELA,SE1->E1_SALDO,_dVencAtu,SE1->E1_I_DTPRO,_cLog})

               _cCliente := SE1->E1_CLIENTE
               _cLoja    := SE1->E1_LOJA
               _cVend1   := SE1->E1_VEND1

               SE1->(DBSkip())
            EndDo

            If _nProrrogados > 0
               _lRet := .T.

               //DBSelectArea("ZM4")
               ZM4->(RecLock("ZM4",.F.))
               ZM4->ZM4_APROV  := RetCodUsr()
               ZM4->ZM4_DTAPRO := Date()
               ZM4->ZM4_STATUS := "A"
               ZM4->(MSUnLock())
            ElseIf _nTit = _nSemSaldo .And. _nTit > 0
               _lRejeitado := .T.
               _lRet := .T.
               _cLog := "Não há titulos com saldo para prorrogação."

               //DBSelectArea("ZM4")
               ZM4->(RecLock("ZM4",.F.))
               ZM4->ZM4_APROV  := RetCodUsr()
               ZM4->ZM4_DTAPRO := Date()
               ZM4->ZM4_STATUS := "R"
               ZM4->ZM4_MOTREJ := _cLog
               ZM4->(MSUnLock())

               //U_ITMsg(_cLog,"Atenção",,3 , , , .T.)
            Else
               _lRet := .F.

               _oModelMaster:LoadValue("ZM4_APROV" ,Space(6))
               _oModelMaster:LoadValue("ZM4_NAPROV",Space(50))
            EndIf

         Else
            _lRejeitado := .T.
            _lRet := .T.
            _cLog := "Não Encontrado titulos deste documento para prorrogação."
            aAdd(_aLog,{.F.,_cFilial,_cDoc,_cSerie,_cTipo,"",0,CTOD(""),CTOD(""),_cLog })

            //U_ITMsg(_cLog,"Atenção",,3 , , , .T.)

            //DBSelectArea("ZM4")
            ZM4->(RecLock("ZM4",.F.))
            ZM4->ZM4_APROV  := RetCodUsr()
            ZM4->ZM4_DTAPRO := Date()
            ZM4->ZM4_STATUS := "R"
            ZM4->ZM4_MOTREJ := _cLog
            ZM4->(MSUnLock())

         EndIf

         _aCab := {"","Filial","Numero Titulo ","Prefixo","Tipo","Parcela","Saldo","Venc. Real","Dt de Prorrogação","Log"}
         //aAdd(_aLog,{_lLog,SE1->E1_FILIAL,SE1->E1_NUM,SE1->E1_PREFIXO,SE1->E1_TIPO,SE1->E1_PARCELA,SE1->E1_SALDO,SE1->E1_VENCREA,SE1->E1_VENCREA + _nDias,_cLog })

   		_cTitAux := "Log de processamento de prorogações"
   		_cMsgTop := "Titulos processados"
         
         _aButtons := {}
         aAdd(_aButtons,{"Visualizar Log",{|| AVISO("Log",oLbxAux:aArray[oLbxAux:nAt][10],{"Fechar"},3)  },"Visualizar Log", "Visualizar Log" }) 

         If Len(_aLog) > 1
      		//ITListBox( _cTitAux , _aHeader , _aCols , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk     , _aColXML , bCondMarca,_bLegenda                      ,_lHasOk,_bHeadClk,_aSX1)
      		U_ITListBox( _cTitAux , _aCab    , _aLog  , .F.      , 2      , _cMsgTop ,          ,         ,         ,     ,        ,_aButtons,       ,             ,          ,           , {|C,L|U_AFIN037L(C,L)}        , .F.   ,         ,     )
         Else
            If !(_nProrrogados > 0)
               //U_ITMsg("Aprovação não efeuada!","Atenção",_cLog,3 , , , .T.)
               U_ITMsg(_cLog,'Atenção!',,1)
            Else
         		//ITListBox( _cTitAux , _aHeader , _aCols , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk     , _aColXML , bCondMarca,_bLegenda                      ,_lHasOk,_bHeadClk,_aSX1)
         		U_ITListBox( _cTitAux , _aCab    , _aLog  , .F.      , 2      , _cMsgTop ,          ,         ,         ,     ,        ,_aButtons,       ,             ,          ,           , {|C,L|U_AFIN037L(C,L)}        , .F.   ,         ,     )
            EndIf
         EndIf
      EndIf

      If _lRet .And. !_lRejeitado
         cEmail := Posicione("SA3",1,xFilial("SA3") +_cVend1,"A3_EMAIL")
         cNomeVend := Posicione("SA3",1,xFilial("SA3") +_cVend1,"A3_NOME")

         cCordenador := Posicione("SA3",1,xFilial("SA3") +_cVend1,"A3_SUPER")
         cEmail += ";" + Posicione("SA3",1,xFilial("SA3") +cCordenador,"A3_EMAIL")
         
         cGerente := Posicione("SA3",1,xFilial("SA3") +_cVend1,"A3_GEREN")
         cEmail += ";" + Posicione("SA3",1,xFilial("SA3") +cGerente,"A3_EMAIL")
         
         If !Empty(AllTrim(ZM4->ZM4_SOLICI))
            cEmail += ";" + UsrRetMail(ZM4->ZM4_SOLICI) 
         EndIf

         U_AFIN037F(_cDoc,Posicione("SA1",1,xFilial("SA1")+_cCliente+_cLoja,"A1_NOME"),cNomeVend,cEmail,_aLog,_lRejeitar,_cMotivo,_aBoletos)
      Else
       	//U_ITMsg("Aprovação não efeuada!","Atenção",,3 , , , .T.)	      
         Help(NIL, 1, "HELP", NIL, "Aprovação não efeuada!", 1, 0, NIL, NIL, NIL, NIL, NIL, {})
      EndIf
      
   EndIf

End Transaction 

Return _lRet

/*
===============================================================================================================================
Programa----------: AFIN037A
Autor-------------: Igor Melgaço
Data da Criacao---: 24/07/2024
Descrição---------: Carrega variaveis
Parametros--------: _oModel = Modelo de dados.
Retorno-----------: _lRet = .T. 
===============================================================================================================================
*/
User Function AFIN037A(_oModel) As Logical
Local _oModelMaster := _oModel:GetModel("ZM4CAB") As Object
Local _nOperation   := _oModel:GetOperation() As Numeric
Local _lRet := .T. As Logical
Local _lRejeitar := !(FWIsInCallStack("U_AFIN037R")) As Logical

   If _nOperation == MODEL_OPERATION_UPDATE
      _oModelMaster:LoadValue("ZM4_DTAPRO",Date())
      _oModelMaster:LoadValue("ZM4_APROV" ,RetCodUsr())
      _oModelMaster:LoadValue("ZM4_NAPROV",UsrFullName(RetCodUsr()))
      _oModelMaster:LoadValue("ZM4_STATUS",IIf(_lRejeitar,"R","A"))
   EndIf

Return _lRet 

/*
===============================================================================================================================
Programa----------: AFIN037B
Autor-------------: Igor Melgaço
Data da Criacao---: 22/07/2024
Descrição---------: Validação de Abertura do cadastro.
Parametros--------: _oModel = Modelo de dados.
Retorno-----------: _lRet = .T. 
===============================================================================================================================
*/
User Function AFIN037B(_oModel) As Logical
Local _nOperation   := _oModel:GetOperation() As Numeric
Local _lRet := .T. As Logical

   If _nOperation == MODEL_OPERATION_UPDATE
      If ZM4->ZM4_STATUS == "A"
         _lRet := .F.
       	U_ITMsg("Registro já aprovado! ",;
          "Atenção",;
          "Selecione um registro que ainda não foi aprovado.",3 , , , .T.)	
      ElseIf ZM4->ZM4_STATUS == "R" 
         _lRet := .F.
       	U_ITMsg("Registro já rejeitado! ",;
          "Atenção",;
          "Selecione um registro que ainda não foi aprovado ou rejeitado.",3 , , , .T.)	
      EndIf
   EndIf

Return _lRet 


/*
===============================================================================================================================
Programa----------: AFIN037
Autor-------------: Igor Melgaço
Data da Criacao---: 26/07/2024
Descrição---------: Monta Legenda
Parametros--------: _aCol,_nLinha
Retorno-----------: cRet
===============================================================================================================================
*/
User Function AFIN037L(_aCol As Array, _nLinha As Numeric) As Char
   Local oVerm := LoadBitmap( , "BR_VERMELHO") As Object // VERMELHO TEM QUE GERA REPOSICAO .F. CRITICO
   Local oVerd := LoadBitmap( , "BR_VERDE"   ) As Object // VERDE ESTOQUE TUDO OK .T.
	If _aCol[_nLinha,1]
		Return oVerd
	Else
		Return oVerm
	EndIf

Return oVerm


/*
===============================================================================================================================
Programa----------: MOMS068F
Autor-------------: Igor Melgaco
Data da Criacao---: 06/03/2024
Descrição---------: WorkFlow para notificação do Vendedor
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AFIN037F(cTit As Char, cDescCli As Char, cDescVend As Char, cEmail As Char, _aLog As Array, _lRejeitado As Logical, _cMotivo As Char, _aBoletos As Array) As Logical
Local cHtml      := "" As Char
Local cTo        := "" As Char
Local cGetCco    := "" As Char
Local cFrom      := "" As Char
Local cFilePrint := "" As Char
Local lRet       := .F. As Logical
Local _cAssunto  := "" As Char
Local _aConfig   := U_ITCFGEML(' ') As Array
Local _cLog      := "" As Char
Local _nTotal    := 0 As Numeric
Local i          := 0 As Numeric
  
Default _aLog := {} 
Default _lRejeitado := .F. 
Default _cMotivo := "" 

      cHtml := 'Prezado '+cDescVend+','
      cHtml += '<br><br>'
      cHtml += '<br><br>'
      If _lRejeitado
         cHtml += '&nbsp;&nbsp;&nbsp;Prorrogação por ocorrencia de frete do Titulo N. '+cTit+' / Cliente: '+AllTrim(cDescCli)+' rejeitada. '
      Else
         cHtml += '&nbsp;&nbsp;&nbsp;Titulo N. '+cTit+' / Cliente: '+AllTrim(cDescCli)+' prorrogado por ocorrencia de frete.'
      EndIf
      cHtml += '<br><br>'
      cHtml += '<br><br>'

      If _lRejeitado 
         If !Empty(_cMotivo)
            cHtml += '&nbsp;&nbsp;&nbsp;Motivo da Rejeição: '+_cMotivo
            cHtml += '<br><br>'
         EndIf
      Else
         For i := 1 to Len(_aLog)
            If _aLog[i,1]
               cHtml += '&nbsp;&nbsp;&nbsp;Titulo '+_aLog[i,3]+IIf(Empty(AllTrim(_aLog[i,6])),'',' / Parcela: '+_aLog[i,6])+' / Saldo: '+Transform(_aLog[i,7],"@E 9,999,999,999.99") + " / Vencto Anterior: " + DToC(_aLog[i,8]) + " / Vencto Atual: " + DToC(_aLog[i,9])
               cHtml += '<br><br>'
               _nTotal += _aLog[i,7]
            EndIf
         Next
      EndIf

      cHtml += '<br><br>'
      cHtml += '&nbsp;&nbsp;&nbsp;A disposição!'
      cHtml += '<br><br>'
      cHtml += '<table class=MsoNormalTable border=0 cellpadding=0>'
      cHtml += '<tr>'
      cHtml +=     '<td style="padding:.75pt .75pt .75pt .75pt">'
      cHtml +=         '<p class=MsoNormal align=center style="text-align:center">'
      cHtml +=             '<b><span style="font-size:18.0pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">'+ "Contas a receber" +'</span></b>'
      cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
      cHtml +=     '</td>'
      cHtml +=     '<td style="background:#A2CFF0;padding:.75pt .75pt .75pt .75pt">&nbsp;</td>'
      cHtml +=     '<td style="padding:.75pt .75pt .75pt .75pt">
      cHtml +=         '<table class=MsoNormalTable border=0 cellpadding=0>'
      cHtml +=              '<tr>'
      cHtml +=                  '<td style="padding:.75pt .75pt .75pt .75pt">'
      cHtml +=                      '<p class=MsoNormal><b><span style="font-size:13.5pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#6FB4E3;mso-fareast-language:PT-BR">' + "Depto Financeiro" + '</span></b>'
      cHtml +=                      '<b><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></b>
      cHtml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"><br></span>
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
      cHtml += '<BR>Ambiente: ['+ GETENVSERVER() +'] / Fonte: [RFIN002] </BR>'
      cHtml +=             '</span>'
      cHtml +=             '<span style="font-size:7.5pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>'
      cHtml +=         '</td>'
      cHtml +=     '</tr>
      cHtml += '</table>'

      cFrom   := SuperGetMV("ITAFIN37EM",.F.,'cobranca@italac.com.br') 
      cTo     := cEmail
      cGetCco := cFrom + "; prorrogacao@italac.com.br "

      If !(AllTrim(GETENVSERVER()) == "PRODUCAO")
         cTo    := "antonio.ramos@italac.com.br;neves.antonio.ramos@gmail.com" 
         cGetCco := "igor.melgaco@italac.com.br" 					
      EndIf
      
      If _lRejeitado
         _cAssunto := "Prorogação de titulo rejeitada Doc.: "+ cTit + " Cliente: " + AllTrim(cDescCli) 
      Else
         _cAssunto := "Titulo Prorogado por ocorrencia de frete " + AllTrim(cDescCli) + " Valor " + AllTrim(Transform(_nTotal,"@E 9,999,999,999.99"))  
      EndIf

      For i := 1 to Len(_aBoletos)
         cFilePrint += IIf(Empty(AllTrim(cFilePrint)),"",";") + _aBoletos[i]
      Next
      
      U_ITENVMAIL( cFrom , cTo ,  ,cGetCco  , _cAssunto , cHtml , cFilePrint , _aConfig[01] , _aConfig[02] , _aConfig[03] , _aConfig[04] , _aConfig[05] , _aConfig[06] , _aConfig[07] , @_cLog )
      
      lRet :=  ("Sucesso" $ _cLog)
      
      U_ItMsg(IIf(lRet,"Email enviado com sucesso para "+cTo+"!","Falha no Envio do email: "+_cLog),"Atenção",,IIf(lRet,2,1))
   
      For i := 1 to Len(_aBoletos)
         If ! Empty(_aBoletos[i]) .And. File(_aBoletos[i]) 
            fErase(_aBoletos[i])
         EndIf
      Next
      
Return

/*
===============================================================================================================================
Programa----------: AFIN037R
Autor-------------: Igor Melgaco
Data da Criacao---: 06/03/2024
Descrição---------: WorkFlow para notificação do Vendedor
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AFIN037R()

FWExecView( "Rejeitar" , "AFIN037" , MODEL_OPERATION_UPDATE ,, {||.T.} , {||.T.} ) 

Return

/*
===============================================================================================================================
Programa----------: AFIN037V
Autor-------------: Igor Melgaco
Data da Criacao---: 30/07/2024
Descrição---------: Abertura da Rotina com a lista de aprovações pendente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AFIN037V()

U_AFIN037(.T.)

Return
