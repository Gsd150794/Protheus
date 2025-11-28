/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço      | 10/11/2025 | Chamado 52859 - Inclusão do campo Z35_BAIRRO e ajuste para inclusão de registro na ZA5
Igor Melgaço      | 21/11/2025 | Chamado 53072 - Inclusão do campo Z35_NUMCAT e Z35_SERCAT na rotina de integração
Igor Melgaço      | 25/11/2025 | Chamado 53072 - Ajuste na numeração da matricula na rotina de integração, colocado mais 2 campos com não obrigatorios.
Igor Melgaço      | 26/11/2025 | Chamado 53072 - Ajuste para mostrar a numeração da matricula antes da integração iniciar.
Igor Melgaço      | 26/11/2025 | Chamado 53072 - Ajuste na numeração da matricula.
===============================================================================================================================
*/

#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "RWMAKE.CH"

                    //1234567890|1234567890|1234567890|1234567890|1234567890|1234567890|1234567890|1234567890|1234567890|1234567890|1234567890|1234567890|1234567890|1234567890|"
Static _cCpoZ35CR := "Z35_END   |Z35_LOGRNU|Z35_COMPL |Z35_BAIRRO|Z35_CODMUN|Z35_CIDADE|Z35_UF    |Z35_PAIS  |Z35_CEP   |Z35_LOGRTP|"
Static _cCpoZ35n  := "Z35_DEPTO |Z35_SETOR |Z35_NSETOR|Z35_TNOTRA|Z35_CODFUN|Z35_FUNCAO|Z35_SEQTUR|Z35_SINDIC|Z35_DSINDI|"
Static _cCpoZ35TE := "Z35_TITULO|Z35_ZONA  |Z35_SECAO |"
Static _cCpoZ35CH := "Z35_HABILI|Z35_CATCNH|Z35_CNHORG|Z35_UFCNH |Z35_DTEMCN|Z35_DTVCCN|Z35_DTINCO|"
Static _cCpoZ35CN := "Z35_MATCER|Z35_LIVCER|Z35_FOLCER|Z35_CARCER|Z35_EMICER|Z35_UFCERT|Z35_CDMUCE|Z35_MUNCER|"
Static _cCpoZ35RG := "Z35_RG    |Z35_NOMECM|Z35_DTNASC|Z35_ORGEMR|Z35_DTRGEX|Z35_MAE   |Z35_PAI    |Z35_NAC  |Z35_CMUNAS|Z35_NACION|Z35_NATURA|Z35_UFRG  |Z35_PAISOR|Z35_NAC   |" 

/*
===============================================================================================================================
Programa----------: AGPE010
Autor-------------: Igor Melgaço
Data da Criacao---: 25/02/2025
Descrição---------: Monitor Gupy. Chamado: 49804 
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/ 
User Function AGPE010() 
   Local _oBrowse    := Nil As Object

   _oBrowse := FWMBrowse():New()
   _oBrowse:SetAlias("Z35")
   _oBrowse:SetMenuDef( 'AGPE010' )
   _oBrowse:SetDescription("Monitor Gupy")
   _oBrowse:AddLegend( "Z35_STATUS=='I'", "GREEN"      ,"Integrado")
   _oBrowse:AddLegend( "Z35_STATUS=='N'", "BLACK"      ,"Nao Integrado")

   _oBrowse:Activate()

Return()

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Igor Melgaço
Data da Criacao---: 25/02/2025
Descrição---------: Rotina de definição automática do menu via MVC
Parametros--------: 
Retorno-----------: aRotina - Definições do menu principal da Rotina.
===============================================================================================================================
*/
Static Function MenuDef() As Array
   Local _aRotina	:= {} As Array

   ADD OPTION _aRotina Title 'Integrar'                    Action 'U_AGPE010A'	   OPERATION 4 ACCESS 0
   ADD OPTION _aRotina Title 'Visualizar'	                 Action 'VIEWDEF.AGPE010'	OPERATION 2 ACCESS 0
   ADD OPTION _aRotina Title 'Alterar'                     Action 'VIEWDEF.AGPE010'	OPERATION 4 ACCESS 0
   ADD OPTION _aRotina Title 'Excluir'                     Action 'VIEWDEF.AGPE010'	OPERATION 5 ACCESS 0¨
   ADD OPTION _aRotina Title 'Integração Word'             Action 'GPEXWORD'	      OPERATION 4 ACCESS 0
   ADD OPTION _aRotina Title 'Atualizar token do webhook'  Action 'U_MGPE030'	      OPERATION 4 ACCESS 0
   //ADD OPTION _aRotina Title 'Incluir'	                    Action 'VIEWDEF.AGPE010'	OPERATION 3 ACCESS 0

Return( _aRotina )

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Igor Melgaço
Data da Criacao---: 25/02/2025
Descrição---------: Rotina de definição do Modelo de Dados do MVC
Parametros--------: 
Retorno-----------: _oModel - Objeto do modelo de dados do MVC 
===============================================================================================================================
*/ 
Static Function ModelDef() As Object
   Local _oStruZ35   := FWFormStruct(1,'Z35',{|x| !(x $ (_cCpoZ35CR+_cCpoZ35n+_cCpoZ35RG+_cCpoZ35CN+_cCpoZ35TE+_cCpoZ35CH))}) As Object
   Local _oStrZ35CR  := FWFormStruct(1,'Z35',{|x| x $ _cCpoZ35CR}) As Object
   Local _oStrZ35RG  := FWFormStruct(1,'Z35',{|x| x $ _cCpoZ35RG}) As Object
   Local _oStrZ35CN  := FWFormStruct(1,'Z35',{|x| x $ _cCpoZ35CN}) As Object
   Local _oStrZ35TE  := FWFormStruct(1,'Z35',{|x| x $ _cCpoZ35TE}) As Object
   Local _oStrZ35CH  := FWFormStruct(1,'Z35',{|x| x $ _cCpoZ35CH}) As Object
   Local _oStruZ35n  := FWFormStruct(1,'Z35',{|x| Alltrim(x) $ _cCpoZ35n}) As Object  //|Z35_HRSDIA|Z35_HRSMES|Z35_HRSEMA|Z35_VIEMRA|Z35_REGRA|Z35_TIPOAD|Z35_CATEG
   Local _oStruZ36   := FWFormStruct(1,"Z36") As Object
   Local _oStruZ37   := FWFormStruct(1,"Z37") As Object
   Local _aZ35Rel    := {} As Array
   Local _aZ36Rel    := {} As Array
   Local _aZ37Rel    := {} As Array
   Local _oModel     := Nil As Object
   Local _bCommit    := {|| U_AGPE010L(_oModel) } As Block
   Local _bPosVal    := {|_oModel| U_AGPE010H(_oModel) } As Block
   Local _aStrZ35    := FWSX3Util():GetListFieldsStruct("Z35", .F.) As Array
   Local _aStrZ37    := FWSX3Util():GetListFieldsStruct("Z37", .F.) As Array
   Local _nI         := 0 As Numeric
   Local _cCposNObr  := "" As Character

   _oModel := MPFormModel():New('AGPE010M' ,  /*bPreValidacao*/ , _bPosVal/*_bPosValidacao*/ , _bCommit /*bCommit*/ , /*bCancel*/)
                 //1234567890|1234567890|1234567890|1234567890|1234567890|1234567890|1234567890|1234567890|1234567890|1234567890|1234567890|1234567890|1234567890|1234567890|1234567890|1234567890|1234567890|"
   _cCposNObr := "|Z35_NSETOR|Z35_DPTO  |Z35_CARGO |Z35_FUNCAO|Z35_FILNOM|Z35_COMPL |Z35_RESERV|Z35_DTFIMC|Z35_ORGEMR|Z35_DTRGEX|Z35_PAI   |Z35_DEFIFI|Z35_MAT   |Z35_OBSDEF|Z35_PIS   |Z35_NUMCAT|Z35_SERCAT|" + _cCpoZ35CH + _cCpoZ35CN + _cCpoZ35TE

   If FwIsInCallStack("U_AGPE010A") //Z35_DPTO|Z35_CARGO|Z35_FUNCAO|Z35_FILNOM|Z35_FILID|Z35_COMPL
      For _nI := 1 To Len(_aStrZ35)
         If !(Subs(_aStrZ35[_nI][1]+Space(10),1,10) $ _cCposNObr)

            If !(Subs(_aStrZ35[_nI][1]+Space(10),1,10) $ (_cCpoZ35CR+_cCpoZ35n+_cCpoZ35RG+_cCpoZ35CN+_cCpoZ35TE+_cCpoZ35CH))
               _oStruZ35:SetProperty( _aStrZ35[_nI][1]	, MODEL_FIELD_OBRIGAT , .T. )

            ElseIf Subs(_aStrZ35[_nI][1]+Space(10),1,10) $ _cCpoZ35CR
               _oStrZ35CR:SetProperty( _aStrZ35[_nI][1]	, MODEL_FIELD_OBRIGAT , .T. )

            ElseIf Subs(_aStrZ35[_nI][1]+Space(10),1,10) $ _cCpoZ35RG
               _oStrZ35RG:SetProperty( _aStrZ35[_nI][1]	, MODEL_FIELD_OBRIGAT , .T. )

            ElseIf Subs(_aStrZ35[_nI][1]+Space(10),1,10) $ _cCpoZ35CN
               _oStrZ35CN:SetProperty( _aStrZ35[_nI][1]	, MODEL_FIELD_OBRIGAT , .T. )

            ElseIf Subs(_aStrZ35[_nI][1]+Space(10),1,10) $ _cCpoZ35TE
               _oStrZ35TE:SetProperty( _aStrZ35[_nI][1]	, MODEL_FIELD_OBRIGAT , .T. )

            ElseIf Subs(_aStrZ35[_nI][1]+Space(10),1,10) $ _cCpoZ35CH
               _oStrZ35CH:SetProperty( _aStrZ35[_nI][1]	, MODEL_FIELD_OBRIGAT , .T. )

            ElseIf Subs(_aStrZ35[_nI][1]+Space(10),1,10) $ _cCpoZ35n
               _oStruZ35n:SetProperty( _aStrZ35[_nI][1]	, MODEL_FIELD_OBRIGAT , .T. )

            EndIf  
         
         EndIf
      Next
      For _nI := 1 To Len(_aStrZ37)
         _oStruZ37:SetProperty( _aStrZ37[_nI][1]	, MODEL_FIELD_OBRIGAT , .F. )
      Next
   Else
      For _nI := 1 To Len(_aStrZ37)
         _oStruZ37:SetProperty( _aStrZ37[_nI][1]	, MODEL_FIELD_OBRIGAT , .F. )
      Next
   EndIf

   _oModel:AddFields('Z35CAB', /*cOwner*/ ,_oStruZ35,/*bPreValidacao*/ , /*_bPosValidacao*/ , /*bCarga*/)

   _oModel:AddFields('Z35CAB_CR','Z35CAB',_oStrZ35CR,/*bLinePre*/, /*bLinePost*/, /*bPreVal*/,/*bPosVal*/, /*bLoad*/)
   _oModel:AddFields('Z35CAB_RG','Z35CAB',_oStrZ35RG,/*bLinePre*/, /*bLinePost*/, /*bPreVal*/,/*bPosVal*/, /*bLoad*/)
   _oModel:AddFields('Z35CAB_CN','Z35CAB',_oStrZ35CN,/*bLinePre*/, /*bLinePost*/, /*bPreVal*/,/*bPosVal*/, /*bLoad*/)
   _oModel:AddFields('Z35CAB_TE','Z35CAB',_oStrZ35TE,/*bLinePre*/, /*bLinePost*/, /*bPreVal*/,/*bPosVal*/, /*bLoad*/)
   _oModel:AddFields('Z35CAB_CH','Z35CAB',_oStrZ35CH,/*bLinePre*/, /*bLinePost*/, /*bPreVal*/,/*bPosVal*/, /*bLoad*/)

   _oModel:AddFields('Z35DETAIL','Z35CAB',_oStruZ35n,/*bLinePre*/, /*bLinePost*/, /*bPreVal*/,/*bPosVal*/, /*bLoad*/)

   _oModel:AddGrid('Z36DETAIL','Z35CAB',_oStruZ36,/*bLinePre*/, /*bLinePost*/, /*bPreVal*/,/*bPosVal*/, /*bLoad*/)
   _oModel:AddGrid('Z37DETAIL','Z35CAB',_oStruZ37,/*bLinePre*/, /*bLinePost*/, /*bPreVal*/,/*bPosVal*/, /*bLoad*/)
   
   aAdd(_aZ35Rel, {'Z35_FILIAL', 'Z35CAB.Z35_FILIAL'} )
   aAdd(_aZ35Rel, {'Z35_CPF'   , 'Z35CAB.Z35_CPF'})

   aAdd(_aZ36Rel, {'Z36_FILIAL', 'Z35CAB.Z35_FILIAL'} )
   aAdd(_aZ36Rel, {'Z36_CPF'   , 'Z35CAB.Z35_CPF'})

   aAdd(_aZ37Rel, {'Z37_FILIAL', 'Z35CAB.Z35_FILIAL'} )
   aAdd(_aZ37Rel, {'Z37_CPF'   , 'Z35CAB.Z35_CPF'})

   _oModel:SetRelation('Z35CAB_CR', _aZ35Rel, Z35->(IndexKey(1)))
   _oModel:SetRelation('Z35CAB_RG', _aZ35Rel, Z35->(IndexKey(1)))
   _oModel:SetRelation('Z35CAB_CN', _aZ35Rel, Z35->(IndexKey(1)))
   _oModel:SetRelation('Z35CAB_TE', _aZ35Rel, Z35->(IndexKey(1)))
   _oModel:SetRelation('Z35CAB_CH', _aZ35Rel, Z35->(IndexKey(1)))

   _oModel:SetRelation('Z35DETAIL', _aZ35Rel, Z35->(IndexKey(1)))
   _oModel:SetRelation('Z36DETAIL', _aZ36Rel, Z36->(IndexKey(2)))
   _oModel:SetRelation('Z37DETAIL', _aZ37Rel, Z37->(IndexKey(1)))

   _oModel:GetModel( 'Z37DETAIL' ):SetOptional( .T. )
   _oModel:GetModel( 'Z36DETAIL' ):SetOptional( .T. )
   _oModel:GetModel( 'Z36DETAIL' ):SetOnlyView( .T. )

   _oModel:SetPrimaryKey( {'Z35_FILIAL','Z35_CPF'} )
   _oModel:SetDescription("Modelo de Dados Monitor Gupy")

Return _oModel

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Igor Melgaço
Data da Criacao---: 25/02/2025
Descrição---------: Rotina de definição da View do MVC
Parametros--------: 
Retorno-----------: _oView - Objeto de exibição do MVC  
===============================================================================================================================
*/ 
Static Function ViewDef() As Object
   Local _oStruZ35  := FWFormStruct(2,'Z35',{|x| !(x $ (_cCpoZ35CR+_cCpoZ35n+_cCpoZ35RG+_cCpoZ35CN+_cCpoZ35TE+_cCpoZ35CH))}) As Object
   Local _oStrZ35CR := FWFormStruct(2,'Z35',{|x| x $ _cCpoZ35CR}) As Object
   Local _oStrZ35RG := FWFormStruct(2,'Z35',{|x| x $ _cCpoZ35RG}) As Object
   Local _oStrZ35CN := FWFormStruct(2,'Z35',{|x| x $ _cCpoZ35CN}) As Object
   Local _oStrZ35TE := FWFormStruct(2,'Z35',{|x| x $ _cCpoZ35TE}) As Object
   Local _oStrZ35CH := FWFormStruct(2,'Z35',{|x| x $ _cCpoZ35CH}) As Object
   Local _oStruZ35n := FWFormStruct(2,'Z35',{|x| Alltrim(x) $ _cCpoZ35n}) As Object
   Local _oStruZ36  := FWFormStruct(2,"Z36") As Object
   Local _oStruZ37  := FWFormStruct(2,"Z37") As Object
   Local _oModel    := FWLoadModel("AGPE010") As Object
   Local _oView     := Nil As Object

   _oView := FWFormView():New()
   _oView:SetModel(_oModel)
    
   _oStruZ37:RemoveField( 'Z37_FILIAL' )
   _oStruZ37:RemoveField( 'Z37_CPF' )
 
   // Configura as estruturas de modelo de dados
   _oView:AddField("VIEW_Z35" ,_oStruZ35,"Z35CAB"   ,,)
   _oView:AddField("VIEW_Z35_CR" ,_oStrZ35CR,"Z35CAB_CR"   ,,)
   _oView:AddField("VIEW_Z35_RG" ,_oStrZ35RG,"Z35CAB_RG"   ,,)
   _oView:AddField("VIEW_Z35_CN" ,_oStrZ35CN,"Z35CAB_CN"   ,,)
   _oView:AddField("VIEW_Z35_TE" ,_oStrZ35TE,"Z35CAB_TE"   ,,)
   _oView:AddField("VIEW_Z35_CH" ,_oStrZ35CH,"Z35CAB_CH"   ,,)

   
   _oView:AddField('VIEW_Z35N',_oStruZ35n,'Z35DETAIL',,)
   _oView:AddGrid('VIEW_Z36'  ,_oStruZ36,'Z36DETAIL',,)
   _oView:AddGrid('VIEW_Z37'  ,_oStruZ37,'Z37DETAIL',,)

   //Setando o dimensionamento de tamanho
   _oView:CreateHorizontalBox('CABEC',100)
   _oView:CreateFolder('FOLDER1','CABEC')

   _oView:AddSheet('FOLDER1','SHEET1','Dados de Integração do Funcionário')
   _oView:AddSheet('FOLDER1','SHEET2','Dados dos Dependentes')
   _oView:AddSheet('FOLDER1','SHEET3','Registros de Integração')

   _oView:CreateHorizontalBox('S1_BOX1',60,,,'FOLDER1','SHEET1')
   
   _oView:CreateFolder('FOLDER2','S1_BOX1')
   _oView:AddSheet('FOLDER2','SHEET_S1_1','Geral')
   _oView:AddSheet('FOLDER2','SHEET_S1_2','Comprovante de Residencia')
   _oView:AddSheet('FOLDER2','SHEET_S1_3','RG')
   _oView:AddSheet('FOLDER2','SHEET_S1_4','Certidão de Nascimento')
   _oView:AddSheet('FOLDER2','SHEET_S1_5','Titulo de Eleitor')
   _oView:AddSheet('FOLDER2','SHEET_S1_6','CNH')
   
   _oView:CreateHorizontalBox('S1_BOX1_S1',100,,,'FOLDER2','SHEET_S1_1')
   _oView:CreateHorizontalBox('S1_BOX1_S2',100,,,'FOLDER2','SHEET_S1_2')
   _oView:CreateHorizontalBox('S1_BOX1_S3',100,,,'FOLDER2','SHEET_S1_3')
   _oView:CreateHorizontalBox('S1_BOX1_S4',100,,,'FOLDER2','SHEET_S1_4')
   _oView:CreateHorizontalBox('S1_BOX1_S5',100,,,'FOLDER2','SHEET_S1_5')
   _oView:CreateHorizontalBox('S1_BOX1_S6',100,,,'FOLDER2','SHEET_S1_6')
   
   _oView:CreateHorizontalBox('S1_BOX2',40,,,'FOLDER1','SHEET1')
   _oView:CreateHorizontalBox('S2_BOX1',100,,,'FOLDER1','SHEET2')
   _oView:CreateHorizontalBox('S3_BOX1',100,,,'FOLDER1','SHEET3')

   //Amarrando a view com as box
   _oView:SetOwnerView('VIEW_Z35','S1_BOX1_S1')
   _oView:SetOwnerView('VIEW_Z35_CR','S1_BOX1_S2')
   _oView:SetOwnerView('VIEW_Z35_RG','S1_BOX1_S3')
   _oView:SetOwnerView('VIEW_Z35_CN','S1_BOX1_S4')
   _oView:SetOwnerView('VIEW_Z35_TE','S1_BOX1_S5')
   _oView:SetOwnerView('VIEW_Z35_CH','S1_BOX1_S6')
   
   _oView:SetOwnerView('VIEW_Z35N','S1_BOX2')
   _oView:SetOwnerView('VIEW_Z37','S2_BOX1')
   _oView:SetOwnerView('VIEW_Z36','S3_BOX1')

   //Habilitando título
   _oView:EnableTitleView('VIEW_Z35N','Dados adicionais não integrados obrigatórios de preenchimento')

   _oView:EnableTitleView('VIEW_Z36','Registros de Payload')
   _oView:EnableTitleView('VIEW_Z37','Dependentes do Funcionario')

   _oView:SetViewProperty("VIEW_Z36", "GRIDSEEK", {.F.})
   _oView:SetViewProperty("VIEW_Z36", "GRIDFILTER", {.F.}) 

   _oView:SetViewProperty("VIEW_Z37", "GRIDSEEK", {.F.})
   _oView:SetViewProperty("VIEW_Z37", "GRIDFILTER", {.F.}) 

   //Tratativa padrão para fechar a tela
   _oView:SetCloseOnOk({||.T.})

Return _oView

/*
===============================================================================================================================
Programa----------: AGPE10L2
Autor-------------: Igor Melgaço
Data da Criacao---: 25/02/2025
Descrição---------: Monta Legenda
Parametros--------: _aCol,_nLinha
Retorno-----------: cRet
===============================================================================================================================
*/
User Function AGPE10L2(_aCol As Array,_nLinha As Numeric) As Object
   Local _oLegenda As Object

   If _aCol[_nLinha,1]
      _oLegenda  := LoadBitmap( , "BR_VERDE"   )
   Else
      _oLegenda := LoadBitmap( , "BR_VERMELHO")
   EndIf

Return _oLegenda


/*
===============================================================================================================================
Programa----------: AGPE010L
Autor-------------: Igor Melgaço
Data da Criacao---: 13/05/2025
Descrição---------: Prepara aexecução do Commit
Parametros--------: _oModel
Retorno-----------: .T.
===============================================================================================================================
*/ 
User Function AGPE010L(_oModel As Object) As Logical
Local lRet := .F. As Logical

FwMsgRun( ,{|oproc| lRet  := U_AGPE010K(_oModel) } , 'Aguarde!' , 'Gravando Registro...' )

Return lRet


/*
===============================================================================================================================
Programa----------: AOMS153K
Autor-------------: Igor Melgaço
Data da Criacao---: 13/05/2025
Descrição---------: Commit
Parametros--------: _oModel
Retorno-----------: .T.
===============================================================================================================================
*/ 
User Function AGPE010K(_oModel As Object) As Logical
   Local _cFilial    := xFilial("Z35") As Character
   Local _oModelZ37  := _oModel:GetModel('Z37DETAIL') As Object
   Local _nOperation := _oModel:GetOperation() As Numeric
   Local _nI         := 0 As Numeric
   Local _nDepend    := 0 As Numeric
   Local _aCposSRA   := {} As Array
   Local _aCabecSRB  := {} As Array
   Local _aCposSRB   := {} As Array
   Local _lContinua  := .F. As Logical
   Local _lRet       := .F. As Logical
   Local _cEnd       := "" As Character
   Local _cErro      := "" As Character
   Local _cErroDep   := "" As Character

   Begin Transaction

      If _nOperation = 4 

         If FwIsInCallStack("U_AGPE010A")

            CursorWait()
            
            _oModel:SetValue("Z35CAB","Z35_STATUS", "N")
            FWFormCommit( _oModel )

            _cMatricula := AGPE010MAT()

            If U_ITMsg("O Funcionário será incluído com este Nr de matricula "+_cMatricula+". Deseja continuar?","Atenção" , , ,2, 2)

               
               _cEnd := AGPE010W(_oModel:GetValue("Z35CAB_CR","Z35_END"))

               DbSelectArea("ZA5")
               DbSetOrder(3)
               If !DbSeek(xFilial("ZA5") + _oModel:GetValue("Z35CAB_CR","Z35_UF")	+_oModel:GetValue("Z35CAB_CR","Z35_CEP"))               
                  RecLock("ZA5",.T.)
                  ZA5->ZA5_FILIAL := xFilial("ZA5")
                  ZA5->ZA5_UF     := _oModel:GetValue("Z35CAB_CR","Z35_UF")
                  ZA5->ZA5_CEP    := _oModel:GetValue("Z35CAB_CR","Z35_CEP")
                  ZA5->ZA5_TPLOGR := _oModel:GetValue("Z35CAB_CR","Z35_LOGRTP")
                  ZA5->ZA5_BAIRRO := _oModel:GetValue("Z35CAB_CR","Z35_BAIRRO")
                  ZA5->ZA5_LOGRAD := _cEnd
                  ZA5->(MsUnLock())
               EndIf

               //Dados de Cabeçalho do ExecAuto do Funcionario
               aadd(_aCposSRA, {"RA_FILIAL"  , _oModel:GetValue("Z35CAB","Z35_FILIAL")       , Nil})
               aAdd(_aCposSRA, {"RA_MAT"	   , _cMatricula                                   , Nil})
               aAdd(_aCposSRA, {"RA_NOME"    , _oModel:GetValue("Z35CAB","Z35_NOME")			, Nil})
               aAdd(_aCposSRA, {"RA_SEXO"	   , _oModel:GetValue("Z35CAB","Z35_SEXO")         , Nil})
               aAdd(_aCposSRA, {"RA_RACACOR" , _oModel:GetValue("Z35CAB","Z35_RACACO")       , Nil})
               aAdd(_aCposSRA, {"RA_ESTCIVI" , _oModel:GetValue("Z35CAB","Z35_ESTCIV")       , Nil})
               aAdd(_aCposSRA, {"RA_GRINRAI" , _oModel:GetValue("Z35CAB","Z35_GRINRA")       , Nil}) //Z36_GRINRA Cod. Grau Instrucao RAIS
               aAdd(_aCposSRA, {"RA_CC"	   , _oModel:GetValue("Z35CAB","Z35_CC")				, Nil})
               aAdd(_aCposSRA, {"RA_ADMISSA" , _oModel:GetValue("Z35CAB","Z35_DTADMI")       , Nil}) //Z36_ADMISS
               aAdd(_aCposSRA, {"RA_TIPOADM" , _oModel:GetValue("Z35CAB","Z35_TIPOAD")       , Nil}) //Z36_TIPOAD
               aadd(_aCposSRA, {'RA_OPCAO'   , Stod('20250707')                              , Nil})
               aadd(_aCposSRA, {'RA_BCDPFGT' ,''                                             , Nil})
               aadd(_aCposSRA, {'RA_CTDPFGT' ,''                                             , Nil})
               aAdd(_aCposSRA, {"RA_HRSMES"  , _oModel:GetValue("Z35CAB","Z35_HRSMES")  		, Nil}) //Z36_HRSMES Horas por mes
               aAdd(_aCposSRA, {"RA_PROCES"  , _oModel:GetValue("Z35CAB","Z35_PROCES")       , Nil}) //Z36_PROCES Cod Processo
               aAdd(_aCposSRA, {"RA_CATFUNC" , _oModel:GetValue("Z35CAB","Z35_CATFUN")			, Nil}) //Z36_CATFUN Categoria Funcionario 
               aAdd(_aCposSRA, {"RA_HRSEMAN" , _oModel:GetValue("Z35CAB","Z35_HRSEMA")  		, Nil}) //Z36_HRSEMA Horas por Semana
               aAdd(_aCposSRA, {"RA_CODFUNC" , _oModel:GetValue("Z35DETAIL","Z35_CODFUN")    , Nil}) //Z36_CODFUN COD fUNÇÃO
               aAdd(_aCposSRA, {"RA_HOPARC " , _oModel:GetValue("Z35CAB","Z35_HOPARC")			, Nil}) //Z36_HOPARC Horas Parcial de trabalho 1=Sim 2=Nao
               aAdd(_aCposSRA, {"RA_SINDICA" , _oModel:GetValue("Z35DETAIL","Z35_SINDIC")		, Nil}) //Z36_SINDIC Código do Sindicato      
               aAdd(_aCposSRA, {"RA_TIPOPGT" , _oModel:GetValue("Z35CAB","Z35_TIPOPG")       , Nil}) //Z36_TIPOPG Tipo de Pagamento M=Mensalista, H=Horista, A=Aprendiz, T=Temporario, P=Prestador de Servico, I=Intermitente
               aAdd(_aCposSRA, {"RA_VIEMRAI" , _oModel:GetValue("Z35CAB","Z35_VIEMRA")			, Nil}) //Z36_VIEMRA Vinculo de Empresa RAIS 
               aadd(_aCposSRA, {'RA_CATEFD'  ,'101'                                          , Nil})
               aAdd(_aCposSRA, {"RA_COMPSAB" , _oModel:GetValue("Z35CAB","Z35_COMPSA")			, Nil}) //Z36_COMPSA Compensacao de Sabado 1=Sim 2=Nao
               aAdd(_aCposSRA, {"RA_CIC"	   , _oModel:GetValue("Z35CAB","Z35_CPF")		      , Nil})
               aAdd(_aCposSRA, {"RA_TNOTRAB" , _oModel:GetValue("Z35DETAIL","Z35_TNOTRA")    , Nil}) //Z36_TNOTRA SR6 tabela de turnos
               aAdd(_aCposSRA, {"RA_REGRA"   , _oModel:GetValue("Z35CAB","Z35_REGRA")			, Nil}) //Z36_REGRA   Regra Apont.  busca dados na tabela SPA 01 REGISTRO DE PONTO   99 SEM REGISTRO PONTO  
               aAdd(_aCposSRA, {"RA_SEQTURN" , _oModel:GetValue("Z35DETAIL","Z35_SEQTUR")		, Nil}) //Z36_SEQTUR 'Seq.Ini.Turn'
               aadd(_aCposSRA, {'RA_TIPENDE' ,'2'                                            , Nil}) //Tipo de Endereço 1 comercial / 2 Residencial
               aadd(_aCposSRA, {'RA_ADTPOSE' ,'***N**'                                       , Nil})
               aAdd(_aCposSRA, {"RA_EMAIL"  , _oModel:GetValue("Z35CAB","Z35_EMAIL")			, Nil})
               aAdd(_aCposSRA, {"RA_PIS"     , _oModel:GetValue("Z35CAB","Z35_PIS")				, Nil})
               aAdd(_aCposSRA, {"RA_DDDCELU" , _oModel:GetValue("Z35CAB","Z35_DDDCEL")       , Nil})
               aAdd(_aCposSRA, {"RA_NUMCELU" , _oModel:GetValue("Z35CAB","Z35_NUMCEL")       , Nil})
               aAdd(_aCposSRA, {"RA_DEFIFIS" , _oModel:GetValue("Z35CAB","Z35_DEFIFI")       , Nil})
               aAdd(_aCposSRA, {"RA_BCDEPSA" , _oModel:GetValue("Z35CAB","Z35_BCDEPS")       , Nil})
               aAdd(_aCposSRA, {"RA_CTDEPSA" , _oModel:GetValue("Z35CAB","Z35_CTDEPS")       , Nil})
               aAdd(_aCposSRA, {"RA_I_AUTFR" , _oModel:GetValue("Z35CAB","Z35_AUTFR")			, Nil}) //Z35_AUTFR  Aut Fretista
               aAdd(_aCposSRA, {"RA_TPCONTR" , _oModel:GetValue("Z35CAB","Z35_TPCONT")			, Nil}) //Z35_TPCONT Tipo de Contrato 1 = Indeterminado 2 = determinando 3 = Intermitente
               aAdd(_aCposSRA, {"RA_CATEG"   , _oModel:GetValue("Z35CAB","Z35_CATEG")			, Nil}) //Z35_CATEG  Categoria de Trabalho usada na SEFIP
               aAdd(_aCposSRA, {"RA_I_SETOR" , _oModel:GetValue("Z35DETAIL","Z35_SETOR")     , Nil}) //Z35_SETOR
               aAdd(_aCposSRA, {"RA_DEPTO"   , _oModel:GetValue("Z35DETAIL","Z35_DEPTO")     , Nil}) //Z35_DEPTO
               aAdd(_aCposSRA, {"RA_CARGO"   , _oModel:GetValue("Z35DETAIL","Z35_CODFUN")		, Nil}) 
               aAdd(_aCposSRA, {"RA_HRSDIA"  , _oModel:GetValue("Z35CAB","Z35_HRSDIA")			, Nil}) //Z35_HRSDIA Horas por dia
               aAdd(_aCposSRA, {"RA_RESERVI" , _oModel:GetValue("Z35CAB","Z35_RESERV")			, Nil}) //Z35_RESERV Reservista 1=Sim 2=Nao
               aAdd(_aCposSRA, {"RA_CLAURES" , _oModel:GetValue("Z35CAB","Z35_CLAURE")       , Nil}) //Z35_CLAURES Reservista 1=Sim 2=Nao
               aAdd(_aCposSRA, {"RA_DTFIMCT" , _oModel:GetValue("Z35CAB","Z35_DTADMI")+90    , Nil}) 
               aAdd(_aCposSRA, {"RA_SALARIO" , _oModel:GetValue("Z35CAB","Z35_SALARI")       , Nil}) 
               aAdd(_aCposSRA, {"RA_TPDEFFI" , _oModel:GetValue("Z35CAB","Z35_TPDEFF")       , Nil}) 
               aAdd(_aCposSRA, {"RA_OBSDEFI" , _oModel:GetValue("Z35CAB","Z35_OBSDEF")       , Nil}) 

               //Comprovante de Residencia
               aAdd(_aCposSRA, {"RA_LOGRTP"  , _oModel:GetValue("Z35CAB_CR","Z35_LOGRTP")       , Nil})
               aAdd(_aCposSRA, {"RA_LOGRDSC" , _cEnd                                            , Nil})
               aAdd(_aCposSRA, {"RA_LOGRNUM" , _oModel:GetValue("Z35CAB_CR","Z35_LOGRNU")		   , Nil})
               aAdd(_aCposSRA, {"RA_COMPLEM" , _oModel:GetValue("Z35CAB_CR","Z35_COMPL")	      , Nil})
               //aAdd(_aCposSRA, {"RA_ENDEREC" , _oModel:GetValue("Z35CAB","Z35_END")		      , Nil})
               aAdd(_aCposSRA, {"RA_NUMENDE" , _oModel:GetValue("Z35CAB_CR","Z35_LOGRNU")		   , Nil})
               aAdd(_aCposSRA, {"RA_ESTADO"  , _oModel:GetValue("Z35CAB_CR","Z35_UF")			   , Nil})
               aAdd(_aCposSRA, {"RA_BAIRRO"  , _oModel:GetValue("Z35CAB_CR","Z35_BAIRRO")			, Nil})
               aAdd(_aCposSRA, {"RA_CODMUN"  , _oModel:GetValue("Z35CAB_CR","Z35_CODMUN") 		, Nil})
               aAdd(_aCposSRA, {"RA_MUNICIP" , _oModel:GetValue("Z35CAB_CR","Z35_CIDADE")       , Nil})
               aAdd(_aCposSRA, {"RA_CEP"	   , _oModel:GetValue("Z35CAB_CR","Z35_CEP")				, Nil})
               aadd(_aCposSRA, {'RA_NCODMUNN', _oModel:GetValue("Z35CAB_CR","Z35_CODMUN")       , Nil})

               //RG
               aAdd(_aCposSRA, {"RA_RG"      , _oModel:GetValue("Z35CAB_RG","Z35_RG")	         , Nil})
               aAdd(_aCposSRA, {"RA_NOMECMP ", _oModel:GetValue("Z35CAB_RG","Z35_NOMECM")             , Nil}) 
               aAdd(_aCposSRA, {"RA_NASC"    , _oModel:GetValue("Z35CAB_RG","Z35_DTNASC")       , Nil})
               aAdd(_aCposSRA, {"RA_ORGEMRG" , _oModel:GetValue("Z35CAB_RG","Z35_ORGEMR")+_oModel:GetValue("Z35CAB_RG","Z35_UFRG")        , Nil})
               aAdd(_aCposSRA, {"RA_RGORG"   , _oModel:GetValue("Z35CAB_RG","Z35_ORGEMR")       , Nil})
               aAdd(_aCposSRA, {"RA_RGUF"    , _oModel:GetValue("Z35CAB_RG","Z35_UFRG")         , Nil}) 
               aAdd(_aCposSRA, {"RA_DTRGEXP" , _oModel:GetValue("Z35CAB_RG","Z35_DTRGEX")       , Nil})
               aAdd(_aCposSRA, {"RA_MAE"     , _oModel:GetValue("Z35CAB_RG","Z35_MAE")          , Nil})
               aAdd(_aCposSRA, {"RA_PAI"     , _oModel:GetValue("Z35CAB_RG","Z35_PAI")          , Nil})
               aadd(_aCposSRA, {'RA_CPAISOR' , _oModel:GetValue("Z35CAB_RG","Z35_PAISOR")       , Nil})
               aAdd(_aCposSRA, {"RA_NACIONA" , _oModel:GetValue("Z35CAB_RG","Z35_NAC")          , Nil}) //Nacionalidade Funcionario   
               aAdd(_aCposSRA, {"RA_NACIONC" , _oModel:GetValue("Z35CAB_RG","Z35_NACION")       , Nil}) //Codigo Nacionalidade RFB          
               aadd(_aCposSRA, {'RA_NATURAL' , _oModel:GetValue("Z35CAB_RG","Z35_NATURA")       , Nil})
               aAdd(_aCposSRA, {"RA_CODMUNN" , _oModel:GetValue("Z35CAB_RG","Z35_CMUNAS")		   , Nil}) //Z35_RESERV Reservista 1=Sim 2=Nao
               
               //CNH
               aAdd(_aCposSRA, {"RA_HABILIT" , _oModel:GetValue("Z35CAB_CH","Z35_HABILI")       , Nil})
               aAdd(_aCposSRA, {"RA_CATCNH"  , _oModel:GetValue("Z35CAB_CH","Z35_CATCNH")       , Nil})
               aAdd(_aCposSRA, {"RA_CNHORG"  , _oModel:GetValue("Z35CAB_CH","Z35_CNHORG")       , Nil})
               aAdd(_aCposSRA, {"RA_UFCNH"   , _oModel:GetValue("Z35CAB_CH","Z35_UFCNH")        , Nil})
               aAdd(_aCposSRA, {"RA_DTEMCNH" , _oModel:GetValue("Z35CAB_CH","Z35_DTEMCN")       , Nil})
               aAdd(_aCposSRA, {"RA_DTVCCNH" , _oModel:GetValue("Z35CAB_CH","Z35_DTVCCN")       , Nil})
               aAdd(_aCposSRA, {"RA_DTINCON" , _oModel:GetValue("Z35CAB_CH","Z35_DTINCO")            , Nil}) //Z35_CLAURES Reservista 1=Sim 2=Nao
               
               //Titulo de Eleitor
               aAdd(_aCposSRA, {"RA_TITULOE" , _oModel:GetValue("Z35CAB_TE","Z35_TITULO")             , Nil}) //Z35_DEPTO
               aAdd(_aCposSRA, {"RA_ZONASEC" , _oModel:GetValue("Z35CAB_TE","Z35_ZONA")			      , Nil}) 
               aAdd(_aCposSRA, {"RA_SECAO"   , _oModel:GetValue("Z35CAB_TE","Z35_SECAO")				   , Nil}) //Z35_HRSDIA Horas por dia
               
               //Certdão de Nascimento
               
               If !Empty(Alltrim(_oModel:GetValue("Z35CAB_CN","Z35_MATCER")))
                  aadd(_aCposSRA,{"RA_TIPCERT", "1" 	   , Nil})
               EndIf

               aadd(_aCposSRA,{"RA_EMICERT"    , _oModel:GetValue("Z35CAB_CN","Z35_EMICER")  	   , Nil})
               aadd(_aCposSRA,{"RA_MATCERT"    , _oModel:GetValue("Z35CAB_CN","Z35_MATCER")  	   , Nil})
               aadd(_aCposSRA,{"RA_LIVCERT"    , _oModel:GetValue("Z35CAB_CN","Z35_LIVCER")  	   , Nil})
               aadd(_aCposSRA,{"RA_FOLCERT"    , _oModel:GetValue("Z35CAB_CN","Z35_FOLCER")  	   , Nil})
               aadd(_aCposSRA,{"RA_CARCERT"    , _oModel:GetValue("Z35CAB_CN","Z35_CARCER")  	   , Nil})
               aadd(_aCposSRA,{"RA_UFCERT"     , _oModel:GetValue("Z35CAB_CN","Z35_UFCERT")  	   , Nil})
               aadd(_aCposSRA,{"RA_CDMUCER"    , _oModel:GetValue("Z35CAB_CN","Z35_CDMUCE")  	   , Nil})
               aadd(_aCposSRA,{"RA_MUNCERT"    , _oModel:GetValue("Z35CAB_CN","Z35_MUNCER")  	   , Nil})

               aadd(_aCposSRA,{"RA_NUMCP"      , _oModel:GetValue("Z35CAB","Z35_NUMCAT")  	      , Nil})
               aadd(_aCposSRA,{"RA_SERCP"      , _oModel:GetValue("Z35CAB","Z35_SERCAT")  	      , Nil})
               
               aAdd(_aCposSRA, {"RA_BHFOL" , "N"	                , Nil}) 
               aAdd(_aCposSRA, {"RA_ACUMBH", "N"	                , Nil}) 
               aAdd(_aCposSRA, {"RA_DEPIR" , "00"	                , Nil})  
               aAdd(_aCposSRA, {"RA_DEPSF" , "00"	                , Nil}) 
               
               //Dados de Cabeçalho do ExecAuto do Dependente
               aadd(_aCabecSRB,{"RA_FILIAL" , _cFilial 		   , Nil})
               aadd(_aCabecSRB,{"RA_MAT"    , _cMatricula 	   , Nil})

               Begin Transaction
                  _cErro := ""
                  lMsErroAuto := .F.
                  _cErroAGPE010 := ""
                  MSExecAuto({|x,y,k,w| GPEA010(x,y,k,w)},NIL,NIL,_aCposSRA,3) 

                  If lMsErroAuto
                     _lContinua := .F.
                     _cErro := "Falha na Inclusão do Funcionário " 
                     _cErro += " MSExecAuto: [ "+MostraErro(Upper(GetSrvProfString("STARTPATH","")),"AGPE010.LOG")+" ]"
                     _cErro += _cErroAGPE010
                     _lContinua := .F.
                     //Help('',1,'AGPE010',,_cErro,1,0) 
                     DisarmTransaction()
                  Else
                     _oModel:SetValue("Z35CAB","Z35_STATUS", "I")
                     _lContinua := .T.
                  EndIf

                  If _lContinua 
                     _nDepend := _oModelZ37:Length()
                     If _nDepend > 0 
                        
                        For _nI := 1 to _nDepend

                           _oModelZ37:Goline(_nI)

                           If !Empty(Alltrim(_oModelZ37:GetValue("Z37_NOME")))
                              aAdd(_aCposSRB, {"RB_COD" 	  , StrZero(_nI,2) 		               , Nil}) // Sec. Depend.
                              aAdd(_aCposSRB, {"RB_CIC" 	  , ALLTRIM(_oModelZ37:GetValue("Z37_DEPCPF")) 	, Nil}) // CIC
                              aAdd(_aCposSRB, {"RB_NOME"   , Alltrim(_oModelZ37:GetValue("Z37_NOME")) 	, Nil}) // Nome
                              aAdd(_aCposSRB, {"RB_SEXO"   , _oModelZ37:GetValue("Z37_SEXO") 	, Nil}) // Sexo
                              aAdd(_aCposSRB, {"RB_DTNASC" , _oModelZ37:GetValue("Z37_DTNASC")	, Nil}) // Dt Nascimento
                              aAdd(_aCposSRB, {"RB_GRAUPAR", _oModelZ37:GetValue("Z37_GRAUPA") 	, Nil}) // Grau Parentesco //C=Cônjuge/Companheiro;F=Filho;E=Enteado;P=Pai/Mãe;O=Agregado/Outros                                                             
                              aAdd(_aCposSRB, {"RB_TIPIR"  , _oModelZ37:GetValue("Z37_TIPIR")  	, Nil}) // Tipo IR //1=s/Lim.Idade;2=Ate 21 Anos;3=Ate 24 Anos;4=Nao é Dep.                                                                          
                              aAdd(_aCposSRB, {"RB_TPDEP"  , _oModelZ37:GetValue("Z37_TPDEP")	, Nil}) // Tipo Dependente
                              aAdd(_aCposSRB, {"RB_TIPSF"  , _oModelZ37:GetValue("Z37_TIPSF")	, Nil}) // Tipo Depend. Sal. Familia 1=s/Lim.Idade;2=Ate 14 Anos;3=Nao é Dependente                                                                                  
                              //aAdd(_aCposSRB, {"RB_TIPENDE", _oModelZ37:GetValue("Z37_TIPEN")	, Nil}) // Tipo de Endereço 1 comercial / 2 Residencial  
                              aAdd(_aCposSRB, {"RB_I_ESTNA", _oModelZ37:GetValue("Z37_ESTNAS")	, Nil})
                              aAdd(_aCposSRB, {"RB_I_CDMUN", _oModelZ37:GetValue("Z37_CDMUN")	, Nil})
                              aAdd(_aCposSRB, {"RB_NUMAT"  , _oModelZ37:GetValue("Z37_NUMAT")	, Nil})
                              aAdd(_aCposSRB, {"RB_DTENTRA", _oModelZ37:GetValue("Z37_DTENTRA")	, Nil})
                              aAdd(_aCposSRB, {"RB_I_MAE"  , _oModelZ37:GetValue("Z37_MAE")	   , Nil})

                              _cErroDep := ""
                              
                              lErro := U_GP020MVC(_cMatricula,_aCposSRB,@_cErroDep)
                              
                              If !lErro
                                 _cErro += " Erro na Inclusão do Dependente "+ Alltrim(_oModelZ37:GetValue("Z37_NOME")) + ". Detalhe do erro: "+_cErroDep
                                  
                                 _lContinua := .F. 
                              EndIf

                           EndIf
                          
                        Next

                     EndIf

                     If _lContinua

                        DbSelectArea("SRA")
                        DbSetOrder(5)
                        If DbSeek(_oModel:GetValue("Z35CAB","Z35_FILIAL")+_oModel:GetValue("Z35CAB","Z35_CPF"))
                           RecLock("SRA",.F.)
                           SRA->RA_LOGRDSC := _cEnd
                           SRA->RA_ENDEREC := AllTrim(_oModel:GetValue("Z35CAB_CR","Z35_LOGRTP")) + ". " + _cEnd
                           SRA->(MsUnlock())
                        EndIf

                        _oModel:SetValue("Z35CAB","Z35_MAT", SRA->RA_MAT )
                        _oModel:SetValue("Z35CAB","Z35_STATUS", "I")
                        FWFormCommit( _oModel )
                        _lRet := .T.
                     Else
                        _lRet := .F.
                        DisarmTransaction()
                     EndIf
                  EndIf
               End Transaction
            Else 
               _lRet := .F.
            EndIf
         Else
            FWFormCommit( _oModel )
            _lRet := .T.
         EndIf
      Else

         FWFormCommit( _oModel )
         _lRet := .T.

      EndIf

   End Transaction

   If !_lRet
      Help(,,'AGPE010',,"Falha na integração do Funcionário. Problema: " + _cErro,1,0,.F., /*hWnd*/ , /*nHeight*/ , /*nWidth*/ , .T. , /*aSoluc*/ )
      //help( cRotina , nLinha , cCampo , cNome , cMensagem , nLinha1 , nColuna , lPop , hWnd , nHeight , nWidth , lGravaLog , aSoluc )
      //U_ITmsg("Falha na integração do Funcionário. Problema: " + _cErro,'Atenção!',"",,,,.F.)  //HELP PARA O MVC
   EndIf

Return _lRet


/*
===============================================================================================================================
Programa----------: AGPE010H
Autor-------------: Igor Melgaço
Data da Criacao---: 13/05/2025
Descrição---------: Commit
Parametros--------: _oModel
Retorno-----------: .T.
===============================================================================================================================
*/ 
User Function AGPE010H(_oModel As Object) As Logical
   
   Local _nOperation := _oModel:GetOperation() As Numeric
   Local _cCPF       := _oModel:GetValue("Z35CAB","Z35_CPF") As Character
   Local _oModelZ37  := _oModel:GetModel('Z37DETAIL') As Object
   Local _lRet       := .T. As Logical
   Local _nI         := 0 As Numeric
   Local _nZ         := 0 As Numeric
   LOcal _nQtdDep    := 0 As Numeric
   Local _cCampo     := "" As Character
   Local _aCampos    := { "Z37_NOME" , "Z37_SEXO" , "Z37_DTNASC" , "Z37_GRAUPA" , "Z37_TIPIR" , "Z37_TPDEP" , "Z37_TIPSF" } As Array

   If _nOperation = 4 .AND. FwIsInCallStack("U_AGPE010A")
      
      DbSelectArea("SRA")
      DbSetOrder(5)
      If SRA->(DbSeek(xFilial("SRA") + _cCPF))
         If SRA->RA_SITFOLH <> "D"
            U_ITMSG("Funcionário já Cadastrado! Matricula: "+SRA->RA_MAT,"Atenção","Verifique o cadastro de Funcionário.",3, , , .T.)
            _lRet := .F.
         EndIf
      EndIf 

      If _lRet
         _nQtdDep := _oModelZ37:Length()

         For _nI := 1 to _nQtdDep
            _oModelZ37:Goline(_nI)
            If !Empty(Alltrim(_oModelZ37:GetValue("Z37_IDINTE")))
               For _nZ := 1 to Len(_aCampos)

                  If Subs(_oModelZ37:GetValue("Z37_NOME"),Len(_oModelZ37:GetValue("Z37_NOME")),1) <> ' '
                     If FWAlertNoYes("Possivelmente o nome do depende "+_oModelZ37:GetValue("Z37_NOME")+" não tenha sido importado completamente da plataforma Gupy pelo fato de que no Protheus a qtd de caracteres do campo é menor. É recomendado que efetue uma verificação. Para continuar e concluir a gravação clique em sim, para cancelar e conferir o preenchimento do campo clique em não?", "Atenção")
                        _lRet := .F.
                        Exit
                     EndIf
                  EndIf

                  _cCampo := _oModelZ37:GetValue(_aCampos[_nZ])
                  If Valtype(_cCampo) == "D"
                     _cCampo := DToC(_cCampo)
                  ElseIf Valtype(_cCampo) == "N"
                     _cCampo := If(_cCampo = 0 ,"",Str(_cCampo, 10, 2))
                  EndIf

                  If Empty(Alltrim(_cCampo))
                     U_ITMSG("Campo "+Alltrim(RetTitle(_aCampos[_nZ]))+" posição "+StrZero(_nI,2)+" não informado!","Atenção","Informe o campo "+Alltrim(RetTitle(_aCampos[_nZ]))+" do dependente.",3, , , .T.)
                     _lRet := .F.
                     Exit
                  EndIf
               Next
            EndIf
            If !_lRet
               Exit
            EndIf  
         Next
      EndIf

   Endif

   If _lRet .and. !(_nOperation == MODEL_OPERATION_DELETE)
      _oModel:SetValue("Z35CAB","Z35_STATUS", "N")
      _oModel:SetValue("Z35CAB","Z35_CPF", _cCPF)
      _oModel:SetValue("Z35CAB","Z35_FILIAL", xFilial("Z35"))
   EndIf

Return _lRet
/*
===============================================================================================================================
Programa----------: AGPE010MAT
Autor-------------: Igor Melgaço
Data da Criacao---: 06/02/2025
Descrição---------: Retorna proximo numero de matricula
Parametros--------: 
Retorno-----------: _cRetorno   
===============================================================================================================================
*/
Static Function AGPE010MAT() As Character
   Local _cRetorno   := "" As Character
   Local _cQuery     := "" As Character
   Local _cAliasTemp := GetNextAlias() As Character
   Local _nTamCampo  := TamSx3("RA_MAT")[1] As Numeric
   Local _cMatricula := "" As Character  
   Local _cFilSRA    := xFilial("SRA") As Character

   If _cFilSRA  = "90"
      _cMatricula := "002000"
   ElseIf _cFilSRA  = "92"
      _cMatricula := "000962"
   EndIf

   //////////////////////////////////////////////////////
   //Resgata MAT de integração
   //////////////////////////////////////////////////////		
   If _cFilSRA  = "90" .OR. _cFilSRA  = "92"

      _cQuery := " SELECT MIN(T1.VALOR + 1) AS PROX_MAT "
      _cQuery += " FROM ( "
      _cQuery += "     SELECT CAST(RA_MAT AS INT) AS VALOR "
      _cQuery += "     FROM " + RetSqlName("SRA") 
      _cQuery += "     WHERE D_E_L_E_T_ = ' ' "
      _cQuery += "       AND RA_FILIAL = '" + _cFilSRA +"' "
      _cQuery += "        AND RA_MAT > '"+_cMatricula+"' "
      _cQuery += " ) T1 "
      _cQuery += " LEFT JOIN ( "
      _cQuery += "     SELECT CAST(RA_MAT AS INT) AS VALOR "
      _cQuery += "     FROM " + RetSqlName("SRA") 
      _cQuery += "     WHERE D_E_L_E_T_ = ' ' "
      _cQuery += "       AND RA_FILIAL = '" + _cFilSRA +"' "
      _cQuery += "        AND RA_MAT > '"+_cMatricula+"' "
      _cQuery += " ) T2 ON T2.VALOR = T1.VALOR + 1 "
      _cQuery += " WHERE T2.VALOR IS NULL "

   Else

      _cQuery := " SELECT MAX(CAST(RA_MAT AS INT) + 1) AS PROX_MAT "
      _cQuery += " FROM " + RetSqlName("SRA")
      _cQuery += " WHERE D_E_L_E_T_ = ' '"
      _cQuery += "  AND RA_FILIAL = '" + _cFilSRA +"' "
   
   EndIf

   MPSysOpenQuery( _cQuery , _cAliasTemp)

   DbSelectArea(_cAliasTemp)
   DbGoTop()

   _cRetorno := StrZero((_cAliasTemp)->PROX_MAT,_nTamCampo)
   
   DbSelectArea("SRA")
   DbSetOrder(1)
   Do While DbSeek(_cFilSRA + _cRetorno)
      _cRetorno := Soma1(_cRetorno)						 // busca o proximo numero disponivel
   EndDo

   Do While !MayIUseCode( "RA_MAT"+_cFilSRA+_cRetorno)  //verifica se esta na memoria, sendo usado
      _cRetorno := Soma1(_cRetorno)						 // busca o proximo numero disponivel
   EndDo

   DbSelectArea(_cAliasTemp)
   DbCloseArea()

Return _cRetorno

/*
===============================================================================================================================
Programa----------: AGPE010A
Autor-------------: Igor Melgaço
Data da Criacao---: 06/02/2025
Descrição---------: Executa a View em modo de alteração para integrar o registro
Parametros--------: cAlias,nReg,nOpc
Retorno-----------: FWExecView
===============================================================================================================================
*/
User Function AGPE010A(cAlias As Character,nReg As Numeric,nOpc As Numeric)

DbSelectArea(cAlias)
DbGoTo(nReg)
If Z35->Z35_STATUS == "N"
   Return FWExecView("Integrar","VIEWDEF.AGPE010",4,/*oDlg*/,/*bCloseOnOk*/,/*bOk*/,/*nPercReducao*/) //AxAltera(cAlias,nReg,nOpc,,,,,)
Else
   U_ITMSG("A integração des registro já foi efetuada!","Atenção","Selecione outro registro que ainda não tenha sido integrado.",3, , , .T.)
EndIf

Return
/*
===============================================================================================================================
Programa----------: AGPE010J
Autor-------------: Igor Melgaço
Data da Criacao---: 13/05/2025
Descrição---------: Inicializa o campo Z38_STATUS
Parametros--------: 
Retorno-----------: _cStatus
===============================================================================================================================
*/ 
User Function AGPE010J()
Local _cStatus := Z35->Z35_STATUS
   
   If ALTERA .AND. FwIsInCallStack("U_AGPE010A")
      _cStatus := "I"
   EndIf
   
Return _cStatus


/*
===============================================================================================================================
Programa----------: GP020MVC
Autor-------------: Igor Melgaço
Data da Criacao---: 13/05/2025
Descrição---------: Gravação da Tabela SRB do ExecAuto
Parametros--------: 
Retorno-----------: _cStatus
===============================================================================================================================
*/ 
User Function GP020MVC(_cMat,_aCposSRB,_cError)
   Local _oModel   := Nil
   Local _oMdlSRB  := Nil
   Local _aLog     := {}
   Local _nCod     := 0
   Local _nTipo    := 1 //Exemplo inclusão / 2-Alteração/Exclusão
   Local _nI       := 0
   Local _lRet     := .T.

   aEval({'SRA','SRB'},{|x|CHKFILE(x)})
   SRA->(DbSetOrder(1))

   If SRA->(DbSeek(xFilial("SRA") + _cMat))
      _oModel := FWLoadModel("GPEA020")
      _oModel:SetOperation(MODEL_OPERATION_UPDATE)
      If (_oModel:Activate())
         _oMdlSRB := _oModel:GetModel("GPEA020_SRB") //instanciamento do modelo

         If _nTipo == 1 //Exemplo Inclusão de novo registro
            If(_oMdlSRB:Length() > 1)
               _nCod := _oMdlSRB:AddLine()
            Else
               If(_oMdlSRB:IsInserted())
                  _nCod := 1
               Else
                  _nCod := _oMdlSRB:AddLine()
               EndIf
            EndIf

            For _nI := 1 to Len(_aCposSRB)
               _oMdlSRB:SetValue(_aCposSRB[_nI][1], _aCposSRB[_nI][2])
            Next

         ElseIf _nTipo == 2 //Exemplo alteração de registro existente
            /*
            If(_oMdlSRB:Length() >= 3)
               _oMdlSRB:GoLine(3) //Posicionamento na linha a ser alterada
            EndIf

            //Campos a serem alterados
            _oMdlSRB:SetValue("RB_NOME" , "ALTER EXECAUTO")
            //Possibilita uso do método DeleteLine() para exclusão do registro posicionado
            */
         EndIf

         If(_oModel:VldData())
             If !(_oModel:CommitData())
                 _aLog := _oModel:GetErrorMessage()
             EndIf
         Else
             _aLog := _oModel:GetErrorMessage()
         EndIf
         If Len(_aLog) > 0
            For _nI := 1 to Len(_aLog)
               If ValType(_aLog[_nI]) == "C"
                 _cError += _aLog[_nI] + Chr(13) + Chr(10)
               EndIf
            Next
            _lRet := .F.
         EndIf
      Else
         _cError := "Falha ao ativar o modelo GPEA020"
         _lRet := .F.
      EndIf
   Else
     _cError := "Funcionario nao encontrado"
     _lRet := .F.
   EndIf
 
Return _lRet

/*
===============================================================================================================================
Programa----------: AGPE010W
Autor-------------: Igor Melgaço
Data da Criacao---: 12/09/2025
Descrição---------: Retorna o endereço sem o tipo de logradouro
Parametros--------: 
Retorno-----------: _cEnd
===============================================================================================================================
*/ 
Static Function AGPE010W(_cEnd As Character) As Character
   Local _aDados  := {} As Array
   Local _nI      := 0 As Numeric
   
   _aDados := U_MGPE029X()
   
   For _nI := 1 To Len(_aDados)
      If UPPER(_aDados[_nI,2]) $ _cEnd
         _cEnd := Alltrim(StrTran(_cEnd,UPPER(_aDados[_nI,2]),""))
         Exit
      EndIf
   Next

Return _cEnd 
