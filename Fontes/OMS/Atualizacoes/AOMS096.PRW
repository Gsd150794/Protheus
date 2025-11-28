/*
===============================================================================================================================
                                    ATUALIZACOES SOFRIDAS DESDE A CONSTRUÇAO INICIAL
===============================================================================================================================
 Autor       |   Data   |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço | 18/06/21 | Chamado 36841. Ajuste na validação do cadastro para Mesoregião e Microregião.
Igor Melgaço | 20/07/21 | Chamado 36841. Ajuste no gatilho do codigo de municipio.
==============================================================================================================================================================
Analista    - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
==============================================================================================================================================================
Vanderlei   - Alex Wallauer - 14/08/24 - 15/10/24 - 48138   - Tratamento do Local de Embarque (ZG5_LOCEMB) no cadastro de Transit Time.
==============================================================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================


#Include "TOTVS.ch"
#Include "FwMVCDef.ch"
#Include "RWMAKE.CH"
#Include "TopConn.ch"
#Include "FWMBROWSE.CH"

/*
===============================================================================================================================
Programa--------: AOMS096
Autor-----------: Josué Danich Prestes
Data da Criacao-: 06/05/2016
===============================================================================================================================
Descrição-------: Cadastro de transit time - Chamado 19347
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/

User Function AOMS096(_lxLocalEmbarque)

Local _aArea   := FWGetArea()
Local _oBrowse , _nX

DEFAULT _lxLocalEmbarque:=.F.
Private _lLocalEmbarque:=_lxLocalEmbarque

_cSelectZLE:="SELECT ZEL_CODIGO, ZEL_DESCRI FROM "+RETSQLNAME("ZEL")+" ZEL WHERE D_E_L_E_T_ = ' ' ORDER BY ZEL_CODIGO " //AND ZEL_FILFIS = '"+_cFilPrc+"'

_aItalac_F3:={}//       1             2          3                          4                                                  5          6                    7         8          9         10         11        12
//AD(_aItalac_F3,{"1CPO_CAMPO1"  ,_cTabela   ,_nCpoChave              , _nCpoDesc                       ,_bCondTab, _cTitAux            , _nTamChv, _aDados , _nMaxSel    , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"M->ZG5_LOCEMB",_cSelectZLE,{|Tab|(Tab)->ZEL_CODIGO},{|Tab|AllTrim((Tab)->ZEL_DESCRI)},         ,"Local de Embarque"  ,         ,         ,1            ,.F.        ,       , } )

//Instânciando FWMBrowse - Somente com dicionário de dados
_oBrowse := FWMBrowse():New()
     
    //Setando a tabela de cadastro de Autor/Interprete
    _oBrowse:SetAlias("ZG5")
    _aCampos:= {}
    _aSX3   := FWSX3Util():GetAllFields( "ZG5" , .T. )
    If _lLocalEmbarque
       _oBrowse:SetFilterDefault( '!Empty(ZG5_LOCEMB)' )
	   For _nX := 1 To Len(_aSX3)
	   	   If !AllTrim(_aSX3[_nX]) $ "ZG5_FILORI/ZG5_LOCAL"
	   	      If GetSx3Cache(_aSX3[_nX],"X3_BROWSE") == "S"
                 aAdd(_aCampos,_aSX3[_nX])
	   	      EndIf
	   	   EndIf
	   Next
    Else
       _oBrowse:SetFilterDefault( 'Empty(ZG5_LOCEMB)' )
	   For _nX := 1 To Len(_aSX3)
	   	   If !AllTrim(_aSX3[_nX]) $ "ZG5_LOCEMB/ZG5_LOCEMD"
	   	      If GetSx3Cache(_aSX3[_nX],"X3_BROWSE") == "S"
                 aAdd(_aCampos,_aSX3[_nX])
	   	      EndIf
	   	   EndIf
	   Next
    EndIf

    _oBrowse:SetOnlyFields( _aCampos )

    //Setando a descrição da rotina
    If _lLocalEmbarque
        aRotina:=MenuDef()
       _oBrowse:SetDescription("Cadastro de transit time por Local de Embarque")
    Else
       _oBrowse:SetDescription("Cadastro de transit time")
    EndIf        
    //_oBrowse:SetMenuDef("AOMS096") 
    //Ativa a Browse
    _oBrowse:Activate()
     
    FWRestArea(_aArea)
    
Return

/*
===============================================================================================================================
Programa--------: AOMS096E
Autor-----------: Alex Walaluer
Data da Criacao-: 13/08/2024
===============================================================================================================================
Descrição-------: Cadastro de transit time por Local de Embarque - Chamado 48138
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/

User Function AOMS096E()

U_AOMS096(.T.)
    
Return

/*
===============================================================================================================================
Programa--------: AOMS096 - MenuDef
Autor-----------: Josué Danich Prestes
Data da Criacao-: 06/05/2016
===============================================================================================================================
Descrição-------: MenuDef do MVC
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function MenuDef()
 
Private _aRot := {}

   ADD OPTION _aRot TITLE 'Visualizar' ACTION 'VIEWDEF.AOMS096' 	OPERATION MODEL_OPERATION_VIEW   ACCESS 0 //OPERATION 2
   ADD OPTION _aRot TITLE 'Incluir'    ACTION 'VIEWDEF.AOMS096' 	OPERATION MODEL_OPERATION_INSERT ACCESS 0 //OPERATION 3
   ADD OPTION _aRot TITLE 'Alterar'    ACTION 'VIEWDEF.AOMS096' 	OPERATION MODEL_OPERATION_UPDATE ACCESS 0 //OPERATION 4
   ADD OPTION _aRot TITLE 'Excluir'    ACTION 'VIEWDEF.AOMS096' 	OPERATION MODEL_OPERATION_DELETE ACCESS 0 //OPERATION 5

Return _aRot

/*
===============================================================================================================================
Programa--------: AOMS096 - ModelDef 
Autor-----------: Josué Danich Prestes
Data da Criacao-: 06/05/2016
===============================================================================================================================
Descrição-------: ModelDef  do MVC
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/ 
 
Static Function ModelDef()

//Criação do objeto do modelo de dados
Local _oModel := Nil
Local _bValid	:= {|_oModel| U_AOMS096V(_oModel)}

//Criação da estrutura de dados utilizada na interface
Local _oStZG5 := FWFormStruct(1, "ZG5")
Local _aGatAux	:= {}

If _lLocalEmbarque
   _oStZG5:RemoveField('ZG5_FILORI')
   _oStZG5:RemoveField('ZG5_LOCAL')   

   _aGatAux := FwStruTrigger( 'ZG5_LOCEMB', 'ZG5_LOCEMD', 'Posicione("ZEL",1,xFilial("ZEL")+M->ZG5_LOCEMB,"ZEL_DESCRI")', .F. )
   _oStZG5:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

Else

   _oStZG5:RemoveField('ZG5_LOCEMB')
   _oStZG5:RemoveField('ZG5_LOCEMD')     

EndIf
//ZG5_CODMUN                                          
_aGatAux := FwStruTrigger( 'ZG5_CODMUN', 'ZG5_MUN', 'Posicione("CC2",1,xFilial("CC2")+M->ZG5_UF+M->ZG5_CODMUN,"CC2_MUN")', .F. )
_oStZG5:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

//ZG5_MESO
_aGatAux := FwStruTrigger( 'ZG5_MESO', 'ZG5_NMESO', 'Posicione("Z21",1,xFilial("Z21")+M->ZG5_MESO,"Z21_NOME")', .F. )
_oStZG5:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZG5_MESO', 'ZG5_MICRO', 'Space(Len(ZG5->ZG5_MICRO))', .F. )
_oStZG5:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZG5_MESO', 'ZG5_NMICRO', '""', .F. )
_oStZG5:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZG5_MESO', 'ZG5_CODMUN', 'Space(Len(ZG5->ZG5_CODMUN))', .F. )
_oStZG5:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZG5_MESO', 'ZG5_MUN', '""', .F. )
_oStZG5:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

//ZG5_MICRO
_aGatAux := FwStruTrigger( 'ZG5_MICRO', 'ZG5_NMICRO', 'Posicione("Z22",1,xFilial("Z22")+M->ZG5_MICRO,"Z22_NOME")', .F. )
_oStZG5:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZG5_MICRO', 'ZG5_CODMUN', 'Space(Len(ZG5->ZG5_CODMUN))', .F. )
_oStZG5:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZG5_MICRO', 'ZG5_MUN', '""', .F. )
_oStZG5:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

//ZG5_UF
_aGatAux := FwStruTrigger( 'ZG5_UF', 'ZG5_MESO', 'Space(Len(ZG5->ZG5_MESO))', .F. )
_oStZG5:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZG5_UF', 'ZG5_NMESO ', '""', .F. )
_oStZG5:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZG5_UF', 'ZG5_MICRO', 'Space(Len(ZG5->ZG5_MICRO))', .F. )
_oStZG5:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZG5_UF', 'ZG5_NMICRO', '""', .F. )
_oStZG5:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZG5_UF', 'ZG5_CODMUN', 'Space(Len(ZG5->ZG5_CODMUN))', .F. )
_oStZG5:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZG5_UF', 'ZG5_MUN', '""', .F. )
_oStZG5:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )


//Instanciando o modelo, não é recomendado colocar nome da User Function (por causa do u_), respeitando 10 caracteres
_oModel := MPFormModel():New("AOMS096M",,_bValid ,/*bCommit*/,/*bCancel*/) 
     
//Atribuindo formulários para o modelo
_oModel:AddFields("FORMZG5",/*cOwner*/,_oStZG5)

//Setando a chave primária da rotina
If _lLocalEmbarque
   _oModel:SetPrimaryKey({'ZG5_FILIAL','ZG5->ZG5_LOCEMB','ZG5->ZG5_UF','ZG5->ZG5_CODMUN','ZG5->ZG5_MESO','ZG5->ZG5_MICRO'})
Else     
   _oModel:SetPrimaryKey({'ZG5_FILIAL','ZG5->ZG5_FILORI','ZG5->ZG5_UF','ZG5->ZG5_CODMUN','ZG5->ZG5_LOCAL','ZG5->ZG5_MESO','ZG5->ZG5_MICRO'})
EndIf     
//Adicionando descrição ao modelo
_oModel:SetDescription("Cadastro de Transit Time")
     
//Setando a descrição do formulário
_oModel:GetModel("FORMZG5"):SetDescription("Cadastro de Transit Time")

Return _oModel


/*
===============================================================================================================================
Programa--------: AOMS096 - ViewDef 
Autor-----------: Josué Danich Prestes
Data da Criacao-: 06/05/2016
===============================================================================================================================
Descrição-------: ViewDef  do MVC
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/  
 
Static Function ViewDef()
 
//Criação do objeto do modelo de dados da Interface do Cadastro de Autor/Interprete
Local _oModel := FWLoadModel("AOMS096")
     
//Criação da estrutura de dados utilizada na interface do cadastro de Autor
Local _oStZG5 := FWFormStruct(2, "ZG5")  //pode se usar um terceiro parâmetro para filtrar os campos exibidos { |cCampo| cCampo $ 'ZG5_NOME|ZG5_DTAFAL|'}
     
//Criando _oView como nulo
Local _oView := Nil

If _lLocalEmbarque
   _oStZG5:RemoveField('ZG5_FILORI')
   _oStZG5:RemoveField('ZG5_LOCAL') 
Else
   _oStZG5:RemoveField('ZG5_LOCEMB')
   _oStZG5:RemoveField('ZG5_LOCEMD')     
EndIf

//Criando a view que será o retorno da função e setando o modelo da rotina
_oView := FWFormView():New()
_oView:SetModel(_oModel)
     
//Atribuindo formulários para interface
_oView:AddField("VIEW_ZG5", _oStZG5, "FORMZG5")
     
//Criando um container com nome tela com 100%
_oView:CreateHorizontalBox("TELA",100)
     
//Colocando título do formulário
_oView:EnableTitleView('VIEW_ZG5', 'Transit Time' )  
     
//Força o fechamento da janela na confirmação
_oView:SetCloseOnOk({||.T.})
     
//O formulário da interface será colocado dentro do container
_oView:SetOwnerView("VIEW_ZG5","TELA")

Return _oView

/*
===============================================================================================================================
Programa--------: AOMS096V
Autor-----------: Josué Danich Prestes
Data da Criacao-: 06/05/2016
===============================================================================================================================
Descrição-------: Validação pré gravação
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: _lOk - lógico permitindo ou não a gravação
===============================================================================================================================
*/  
User Function AOMS096V(_oModel)

Local _lOk        := .T.
Local _nOperation := _oModel:GetOperation() 
Local _cUF        := _oModel:GetValue( 'FORMZG5', 'ZG5_UF' )
Local _cCodMun    := _oModel:GetValue( 'FORMZG5', 'ZG5_CODMUN' )
Local _cMeso      := _oModel:GetValue( 'FORMZG5', 'ZG5_MESO' )
Local _cMicro     := _oModel:GetValue( 'FORMZG5', 'ZG5_MICRO' )
Local _cFilOrig   := ""
Local _cLocal     := ""
Local _cLocEmb    := ""
Local _lValida    := .F.
Local _aOrd       := SaveOrd({"ZG5"})

If _lLocalEmbarque//ZG5_FILIAL+ZG5_LOCEMB+ZG5_UF+ZG5_CODMUN+ZG5_MESO+ZG5_MICRO
   _cLocEmb :=_oModel:GetValue( 'FORMZG5', 'ZG5_LOCEMB' )
Else
   _cFilOrig:= _oModel:GetValue( 'FORMZG5', 'ZG5_FILORI' ) 
   _cLocal  := _oModel:GetValue( 'FORMZG5', 'ZG5_LOCAL' )
EndIf

If _nOperation == MODEL_OPERATION_INSERT 
    _lValida      := .T.
ElseIf _nOperation == MODEL_OPERATION_UPDATE
    If _lLocalEmbarque//ZG5_FILIAL+ZG5_LOCEMB+ZG5_UF+ZG5_CODMUN+ZG5_MESO+ZG5_MICRO
       If (_cLocEmb + _cUF + _cCodMun + _cMeso + _cMicro) <> (ZG5->ZG5_LOCEMB + ZG5->ZG5_UF + ZG5->ZG5_CODMUN + ZG5->ZG5_MESO + ZG5->ZG5_MICRO)
           _lValida      := .T.
       EndIf
    Else
       If (_cFilOrig + _cUF + _cCodMun + _cLocal + _cMeso + _cMicro) <> (ZG5->ZG5_FILORI + ZG5->ZG5_UF + ZG5->ZG5_CODMUN + ZG5->ZG5_Local + ZG5->ZG5_MESO + ZG5->ZG5_MICRO)
           _lValida      := .T.
       EndIf
    EndIf
EndIf

If _lValida
    If _lLocalEmbarque
        ZG5->(DBSetOrder(5)) // ZG5_FILIAL+ZG5_LOCEMB+ZG5_UF+ZG5_CODMUN+ZG5_MESO+ZG5_MICRO
	    If ZG5->( DBSeek(xFilial("ZG5") + _cLocEmb + _cUF + _cCodMun +  _cMeso + _cMicro) )    
	       _lOk := .F.
	       U_ITMsg("Chave (Local de Embarque + Estado + Cod. Municipio + Cod. Mesoregiao + Cod Microregiao) informada já consta no cadastro. ",;
                   "Atenção",;
                   "Verifique e modifique o chave digitada.  ",3 , , , .T.)	
	    EndIf
    Else
        ZG5->(DBSetOrder(1)) // ZG5_FILIAL+ZG5_FILORI+ZG5_UF+ZG5_CODMUN+ZG5_LOCAL+ZG5_MESO+ZG5_MICRO
	    If ZG5->( DBSeek(xFilial("ZG5") + _cFilOrig + _cUF + _cCodMun + _cLocal + _cMeso + _cMicro) )    
	       _lOk := .F.
	       U_ITMsg("Chave (Fil Origem + Estado + Cod. Municipio + Armazem + Cod. Mesoregiao + Cod Microregiao) informada já consta no cadastro. ",;
                   "Atenção",;
                   "Verifique e modifique o chave digitada.  ",3 , , , .T.)	
	    EndIf
    EndIf
EndIf

RestOrd(_aOrd)

Return _lOk
