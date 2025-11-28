/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MEST020
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 27/12/2021
Descrição---------: Manutenção tipo de embalagem - Chamado 38733
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MEST020()
Local _aParRet :={}
Local _aParAux :={}  , nI
Local _bOK     :={|| U_ITMsg("Confirma Atualizacao dos Produtos selecionados ?",'Atencao!',,3,2,2) }

_cSelectSBZ:="SELECT BZ_COD , BZ_I_DESCR FROM "+RETSQLNAME("SBZ")+" SBZ WHERE D_E_L_E_T_ = ' ' AND SBZ.BZ_FILIAL = '" + xFilial("SBZ")+"' "
_cSelectSBZ+=" AND EXISTS (SELECT 'Y' FROM "+RETSQLNAME("SB1")+" SB1 WHERE  SBZ.BZ_COD = SB1.B1_COD AND D_E_L_E_T_ = ' ' AND B1_MSBLQL <> '1' AND B1_TIPO <> 'PA') "
_cSelectSBZ+=" ORDER BY BZ_COD "
_aItalac_F3:={}//       1           2         3                      4                      5               6                    7         8          9         10         11        12
//AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela ,_nCpoChave          , _nCpoDesc              ,_bCondTab    , _cTitAux         , _nTamChv , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR01" ,_cSelectSBZ,{|Tab|(Tab)->BZ_COD},{|Tab|(Tab)->BZ_I_DESCR},             ,"Produtos SBZ"    ,          ,          ,          ,.T.        ,       , } )

MV_PAR01:=Space(200)
MV_PAR02:=2
aAdd( _aParAux , { 1 , "Produtos"         , MV_PAR01, "@!"  , ""  ,"F3ITLC", ""    , 100 , .F. } ) 
aAdd( _aParAux , { 3 , " Se origem em branco sobrepor destino ", MV_PAR02, {"1-Sim","2-Nao"}, 040 ,"",.T.}) 

For nI := 1 To Len( _aParAux )
    aAdd( _aParRet , _aParAux[nI][03] )
Next nI
          //aParametros, cTitle                         , @aRet    ,[bOk], [ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ] 
If !ParamBox( _aParAux , "Manutenção tipo de embalagem" , @_aParRet, _bOK, /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
    Return .F.
EndIf

U_ITLOGACS()

cTimeInicial:=Time()

oProcess:= MsNewProcess():New({|_lEnd,oProcess| MEST020G(@oProcess, @_lEnd) }, "Hora Inicial: "+cTimeInicial,"Processando Aguarde...",.T.)      
oProcess:Activate()
Return

/*
===============================================================================================================================
Programa----------: MEST020G
Autor-------------: Alex Wallauer
Data da Criacao---: 27/12/2021
Descricao---------: Replica o campo BZ_I_TPEMB
Parametros--------: _oSelf,_lEnd
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function  MEST020G(_oSelf,_lEnd)
Local cQry1		:= ""
Local _cAlias  := GetNextAlias()

_lEnd:= .F.
_oSelf:SetRegua1( 3 )
_oSelf:SetRegua2( 3 )
_oSelf:IncRegua1("Selelecionando Itens,  Aguarde..." )
_oSelf:IncRegua2("Iniciando os trabalhos, Aguarde..." )

cQry1:="SELECT R_E_C_N_O_ SBZ_REC FROM "+RETSQLNAME("SBZ")+" SBZ WHERE D_E_L_E_T_ = ' ' AND SBZ.BZ_FILIAL <> '" + xFilial("SBZ")+"' "

//Filtra PRODUTO
If !Empty(MV_PAR01)
   cQry1 += " AND BZ_COD IN "+FormatIn(AllTrim(MV_PAR01),";")
EndIf 

   cQry1+=" AND EXISTS (SELECT 'Y' FROM "+RETSQLNAME("SB1")+" SB1 WHERE  SBZ.BZ_COD = SB1.B1_COD AND SB1.D_E_L_E_T_ = ' ' AND SB1.B1_MSBLQL  <> '1' AND SB1.B1_TIPO  <> 'PA') "
If MV_PAR02 = 2 
   cQry1+=" AND EXISTS (SELECT 'Y' FROM "+RETSQLNAME("SBZ")+" BZ2 WHERE  SBZ.BZ_COD = BZ2.BZ_COD AND BZ2.D_E_L_E_T_ = ' ' AND BZ2.BZ_I_TPEMB <> ' ' AND BZ2.BZ_FILIAL = '" + xFilial("SBZ")+"' ) "
EndIf
cQry1+=" ORDER BY BZ_FILIAL, BZ_COD "   

//crio o novo alias
MPSysOpenQuery( cQry1, _cAlias ) 

_oSelf:IncRegua1("Selelecionando Itens,  Aguarde..." )
_oSelf:IncRegua2("Iniciando os trabalhos, Aguarde..." )

nTotal:=nConta:=nGravou:=0
DBSelectArea(_cAlias)
COUNT TO nTotal
(_cAlias)->(DBGoTop())
_aDados:={}
_oSelf:SetRegua1( nTotal )
_oSelf:SetRegua2( nTotal )

nTotal:=AllTrim(Str(nTotal))
nTam:=Len(nTotal)+1
SBZ->(DBSetOrder(1))

While !(_cAlias)->(Eof())

   If _lEnd 
      U_ITMsg("PROCESSAMENTO CANCELADO PELO USUARIO",'Atencao!',,3)
      Exit
   EndIf

   SBZ->(DBGoTo( (_cAlias)->SBZ_REC ))   
   nConta++
   _oSelf:IncRegua1("Lendo "+StrZero(nConta,nTam)+" de "+nTotal +" - Atualizandos: " +AllTrim(Str(nGravou)))
   _oSelf:IncRegua2("Atualizando Filial  / Item: " +SBZ->BZ_FILIAL+" / "+SBZ->BZ_COD)

   _aItens:={}
   aAdd(_aItens,SBZ->BZ_FILIAL ) 
   aAdd(_aItens,SBZ->BZ_COD    ) 
   aAdd(_aItens,SBZ->BZ_I_DESCR) 
   _cSalvaItem:=SBZ->BZ_COD    //DESTINO
   _cSalvaTipo:=SBZ->BZ_I_TPEMB//DESTINO
   If !SBZ->(DBSeek(xFilial("SBZ")+_cSalvaItem))
      aAdd(_aItens,"Produto não encontrado na filial Atual" )//FILIAL ORIGEM ATUAL 
      aAdd(_aItens,_cSalvaTipo )//FILIAL DESTINO ATUAL
      aAdd(_aItens,_cSalvaTipo )//FILIAL TIPO DESTINO ATUALIZADO
      aAdd(_aDados,_aItens)
      (_cAlias)->(DBSkip())
	  Loop
   Else
      aAdd(_aItens,SBZ->BZ_I_TPEMB)//FILIAL ORIGEM ATUAL 
      aAdd(_aItens,_cSalvaTipo    )//FILIAL DESTINO ATUAL
      _cSalvaTipo:=SBZ->BZ_I_TPEMB //FILIAL ORIGEM ATUAL 
   EndIf   
   SBZ->(DBGoTo( (_cAlias)->SBZ_REC ))   
   If MV_PAR02 = 1 .Or. !Empty(_cSalvaTipo)//GRAVA SE = 1 OU senão é branco o campo
      SBZ->(RecLock( "SBZ" , .F. ) )
      SBZ->BZ_I_TPEMB:= _cSalvaTipo//GRVANDO A FILIAL ORIGEM ATUAL NA FILIAL DESTINO
      SBZ->( MSUnLock() )  
	   nGravou++
   EndIf   

   aAdd(_aItens,SBZ->BZ_I_TPEMB )//FILIAL TIPO DESTINO ATUALIZADO
   aAdd(_aDados,_aItens)

   (_cAlias)->(DBSkip())
EndDo

If Len(_aDados) = 0 
   U_ITMsg("Não ha dados para essa selecao",'Atencao!',,3)
EndIf

While Len(_aDados) > 0 
   _aTit:={}
   _aSiz:={}

//Colunas:
//FILIAL; NUMERO SC; ITEM SC; COD PROD; DESCRIï¿½ï¿½O; U.M.; QUANT SC; QUANT ENTREG; 2A. U.M.; QUANT 2A. U.M.; DT ENTREGA SC; OBS;
// DT EMISSAO; SOLICITANTE; STATUS APROV; URGENTE?; APROVADOR; DT APROVAï¿½ï¿½O; COMPRADOR; APLICAï¿½ï¿½O; OBS APROV; USO DIRETO?; NUM PEDIDO; QUANT PC; 
//QUANT ENTREG PC; RESIDUO PC; PC ENCERRADO?; COD APROV PC;STATUS
   aAdd(_aTit,'FILIAL') 
   aAdd(_aSiz,20)
   aAdd(_aTit,'PRODUTO')
   aAdd(_aSiz,25)
   aAdd(_aTit,'DESCRICAO')
   aAdd(_aSiz,20)
   aAdd(_aTit,'TIPO ORIGEM ['+xFilial("SBZ")+']')
   aAdd(_aSiz,100)
   aAdd(_aTit,'TIPO DESTINO ATUAL')
   aAdd(_aSiz,100)
   aAdd(_aTit,'TIPO DESTINO ATUALIZADO')
   aAdd(_aSiz,100)

   _cTitulo:="Produtos atualizados ["+AllTrim(Str(nGravou))+"] - H.I.: "+cTimeInicial+" H.F.: "+Time()

   _cMsgTop:="Produtos selecionados: "+If(Empty(MV_PAR01),"TODOS",MV_PAR01)

   //                           , _aCols  ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons )
      U_ITListBox(_cTitulo,_aTit,_aDados  , .T.    , 3    ,_cMsgTop,          ,_aSiz   ,         ,     ,        , )
                                                                                                  

   If  !U_ITMsg("Confirma Sair ?",'Atencao!',,3,2,2)
       Loop
   EndIf

    Exit

EndDo

Return
