/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |09/05/2025| Chamado 50617. Corrigir chamada estática no nome das tabelas do sistema
Lucas Borges  |23/07/2025| Chamado 51340. Ajustar função para validação de ambiente de teste
Lucas Borges  |14/09/2025| Chamado 51799. Implementada função para validar ambiente de teste totvs.framework.environment.Type.get()
===============================================================================================================================
*/

#Include 'FWMVCDEF.CH'
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: ACOM003
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 20/08/2015                                    .
Descrição---------: Cadastro de Centro de Investimento.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM003()

Local cAlias:= "ZZI"
Local aCores :=	{	{"ZZI_MSBLQL = '1'", 'BR_VERMELHO' },;
							{"ZZI_TIPO = ' '", 'BR_PRETO'	 },;
							{"ZZI_TIPO = '1'", 'BR_VERDE'	 },;
							{"ZZI_TIPO = '2'", 'BR_AZUL'},;
							{"ZZI_TIPO = '3'", 'BR_AMARELO' } }
Local _aParRet :={}
Local _aParAux :={} , nI 

Private _cTipoIni:=""

ZZL->(DBSetOrder(3)) //ZZL_FILIAL + ZZL_CODUSU
If ZZL->(DBSeek(xFilial("ZZL") + __cUserId))

   Private cCadastro := "Cadastro de Centro de Investimento"
   Private aRotina	:= {}                
   Private aSubRotina:= {}                
    
	aAdd(aSubRotina,{"Incluir Nivel 1","U_ACOM003I",0,3})
   aAdd(aSubRotina,{"Incluir Nivel 2","U_ACOM003I",0,3})
   aAdd(aSubRotina,{"Incluir Nivel 3","U_ACOM003I",0,3})
    
   aAdd(aRotina,{"Pesquisar" ,"AxPesqui"  ,0,1})
   aAdd(aRotina,{"Visualizar","U_ACOM03V" ,0,2})
   aAdd(aRotina,{"Incluir"	  ,aSubRotina  ,0,3})
   aAdd(aRotina,{"Alterar"	  ,"U_ACOM003I",0,4})
   aAdd(aRotina,{"Excluir"	  ,"U_ACOM003E(.F.)",0,5})
   aAdd(aRotina,{"Legenda"	  ,"U_ACOM03L",0,5})

   _aOpcoes:={}
   aAdd( _aOpcoes , "1–NIVEL 1")
   aAdd( _aOpcoes , "2–NIVEL 2")
   aAdd( _aOpcoes , "3–NIVEL 3")
   aAdd( _aOpcoes , "4–SEM FILTRO") 
   MV_PAR01:=1 

   aAdd( _aParAux , { 3 , "Filtrar", MV_PAR01, _aOpcoes, 50, "", .T., .T. , .T. } )

    For nI := 1 To Len( _aParAux )
	    aAdd( _aParRet , _aParAux[nI][03] )
    Next nI
    _cFiltro:=NIL
    If !ParamBox( _aParAux , "FILTROS" , @_aParRet,,, .T. , , , , , .T. , .T. )
  		 Return .F.
    EndIf
    If MV_PAR01 <> 4
       _cFiltro:=" ZZI_TIPO = '"+Str(MV_PAR01,1)+"' "
    EndIf

   DBSelectArea(cAlias)
   DBSetOrder(1)
   mBrowse(,,,,cAlias,,,,,,aCores,,,,,,,,_cFiltro)

Else
	FWAlertInfo("O usuário: " + cUserName + " não possui permissão para utilizar este cadastro.",;
		    "Verificar com a área de TI a possibilidade de habilitar o seu usuário.","ACOM00301")
EndIf

Return

/*
===============================================================================================================================
Programa----------: ACOM03L
Autor-------------: Alex Walaluer
Data da Criacao---: 30/03/2021                                    .
Descrição---------: Função utilizada para montar a legenda
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM03L

aLegenda :=	{{"BR_VERDE"	, "NIVEL 1"	 },;
				 {"BR_AZUL"	   , "NIVEL 2"	 },;
				 {"BR_AMARELO"	, "NIVEL 3"	 },;
				 {"BR_VERMELHO", "BLOQUEADO"},;
				 {"BR_PRETO"	, "SEM NIVEL"} }

BrwLegenda("INVESTIMENTOS","Legenda",aLegenda)

Return

/*
===============================================================================================================================
Programa----------: ACOM03V
Autor-------------: Alex Walaluer
Data da Criacao---: 01/03/2021                                    .
Descrição---------: Cadastro de Centro de Investimento.
Parametros--------: cAlias,nReg,nOpc
Retorno-----------: nOpc
===============================================================================================================================
*/
User Function ACOM03V(cAlias,nReg,nOpc)

Local _aBotoes:= {}

aAdd( _aBotoes, {'NOTE',{||U_ACOM03Wrkf("NIVEISV")},"VISUALIZA NIVEIS"})  

If ZZI->ZZI_TIPO $ "1,2" 
   ACOM03Tela(cAlias,nReg,nOpc,_aBotoes)
   Return nOpc
EndIf

Private _aDadosGrava:={}
AxVisual(cAlias,nreg,nOpc; //cAlias,nReg,nOpc,aAcho,nColMens,cMensagem,cFunc,aButtons,lMaximized,cTela,lPanelFin,oFather,oEnc01,lCriaBut,aDim,cStack,aCpos
  	   , /*<aAcho>*/;
	   , /*<nColMens> */;
	   , /*<cMensagem>*/;
	   , /*<cFunc>   */;
	   , /*<aButtons>*/_aBotoes)
Return nOpc

/*
===============================================================================================================================
Programa----------: ACOM003I
Autor-------------: Alex Walaluer
Data da Criacao---: 01/03/2021                                    .
Descrição---------: Cadastro de Centro de Investimento.
Parametros--------: cAlias,nReg,nOpc
Retorno-----------: nOpc
===============================================================================================================================
*/
User Function ACOM003I(cAlias,nReg,nOpc)

Local _aBotoes:=Nil

Private _aDadosGrava:={}

If nOpc = 1     //Incluir NIVEL 1
   _cTipoIni:="1"
ElseIf nOpc = 2 //Incluir NIVEL 2
   _cTipoIni:="2"
ElseIf nOpc = 3 //Incluir NIVEL 3
   _cTipoIni:="3"
ElseIf nOpc = 4 //Alterar

  If ZZI->ZZI_TIPO $ "1,2" 
     _aBotoes:= {}
     aAdd( _aBotoes, {'NOTE'     ,{||U_ACOM03Wrkf("NIVEIS")},"Visualiza Niveis/Acerto"})  
     aAdd( _aBotoes, {'NOTE'     ,{||U_ACOM03Wrkf("BOTAO") },"Vincula Niveis Abaixo"  })  
  EndIf

  If ZZI->ZZI_TIPO $ "1,2" 
     ACOM03Tela(cAlias,nReg,nOpc,_aBotoes)
     Return nOpc
  EndIf

  AxAltera(cAlias,nreg,nOpc; 
  	   , /*<aAcho>*/;
	   , /*<aCpos>*/;
	   , /*<nColMens> */;
	   , /*<cMensagem>*/;
	   , /*<cTudoOk>*/  'U_ACOM03Wrkf("VALGRV" )';//GRAVA // antes 
	   , /*<cTransact>*/'U_ACOM03Wrkf("GRVA")';//depois 
	   , /*<cFunc>   */;
	   , /*<aButtons>*/_aBotoes;
	   , /*<aParam>  */;
	   , /*<aAuto>*/;
	   , /*<lVirtual>*/;
	   , /*<lMaximized>*/)
   
   Return nOpc
EndIf

If _cTipoIni $ "1,2" 
   _aBotoes:= {}
   aAdd( _aBotoes, {'NOTE'     ,{||U_ACOM03Wrkf("BOTAO") },"Vincula Niveis Abaixo"  })  
EndIf

AxInclui(cAlias,nreg,nOpc,;
       /*aAcho>     */ ,;
       /*cFunc>     */ ,;
       /*aCpos>     */ ,;
       /*cTudoOk>   */ 'U_ACOM03Wrkf("VALGRV" )',;
       /*lF3>       */ ,;
       /*cTransact> */ 'U_ACOM03Wrkf("GRVI")',;//Antes 
       /*aButtons>  */ _aBotoes,;
       /*aParam>    */ ,;
       /*aAuto>     */ ,;
       /*lVirtual>  */ ,;
       /*lMaximized>*/ )

// Grava log do Cadastro de Centro de Investimento.
U_ITLOGACS('ACOM003')

Return nOpc

/*
===============================================================================================================================
Programa----------: ACOM003E
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 20/08/2015                                    .
Descrição---------: Função criada para fazer a validação da exclusão do registro.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM003E(_lSoValida)

Local _aArea	 := ZZI->(GetArea())
Local _cQry		 := ""
Local _cAlias	 := GetNextAlias()
Local _nRecAtual  := ZZI->(RECNO())
Local  cZZI_TIPO  := ZZI->ZZI_TIPO
Local  cZZI_CODINV:= ZZI->ZZI_CODINV
Local  _lRet := .T.

Begin Sequence

   _cLista:=ZZI->ZZI_CODINV+" ;"
   If Left(cZZI_TIPO,1) = "1"
      ZZI->(DBSetOrder(3))//ZZI_FILIAL+ZZI_INVPAI
      If ZZI->(DBSeek(xFilial() + cZZI_CODINV ))
         While ZZI->(!Eof()) .And. xFilial("ZZI")+cZZI_CODINV == ZZI->ZZI_FILIAL+ZZI->ZZI_INVPAI
            _cLista+=ZZI->ZZI_CODINV+" ;"
            ZZI->(DBSkip())
         EndDo        
      EndIf
   ElseIf Left(cZZI_TIPO,1) = "2"
      ZZI->(DBSetOrder(4))//ZDA_FILIAL+ZZI_NIVEL2
      If ZZI->(DBSeek(xFilial() + cZZI_CODINV  ))
         While ZZI->(!Eof()) .And. xFilial("ZZI")+cZZI_CODINV  == ZZI->ZZI_FILIAL+ZZI->ZZI_NIVEL2
            _cLista+=ZZI->ZZI_CODINV+" ;"
            ZZI->(DBSkip())
         EndDo        
      EndIf		
   EndIf
   _cLista:=Left(_cLista,Len(_cLista)-1)
   _cQry := "SELECT C1_NUM "
   _cQry += "FROM " + RetSqlName("SC1") + " "
   _cQry += "WHERE C1_FILIAL = '" + xFilial("SC1") + "' "
   _cQry += " AND (C1_I_CDINV IN " + FormatIn(_cLista,";")
   _cQry += "   OR C1_I_SUBIN IN " + FormatIn(_cLista,";")+")"
   _cQry += "  AND C1_RESIDUO = ' ' "
   _cQry += "  AND C1_PEDIDO  = ' ' "
   _cQry += "  AND D_E_L_E_T_ = ' ' "
   _cQry += "  ORDER BY C1_NUM"
   _cQry := ChangeQuery(_cQry)
   MPSysOpenQuery(_cQry,_cAlias)	
   	
   (_cAlias)->( DBGoTop() )
   _cListaSC:=""
   While (_cAlias)->( !Eof() )
      If !(_cAlias)->C1_NUM $ _cListaSC
         _cListaSC+=(_cAlias)->C1_NUM+", "
      EndIf
      (_cAlias)->( DBSkip() )
   EndDo
   _cListaSC:=Left(_cListaSC,Len(_cListaSC)-2)
	If !Empty(_cListaSC)
      FWAlertWarning("Exclusão não permitida Investimento já utilizado em Solicitacoes de Compras. SC(s) :"+_cListaSC,"ACOM00302")
      _lRet := .F.
      ZZI->(DBGoTo(_nRecAtual))
	Else
      If !Empty(_cLista)
         _cLista:="Niveis abaixos: "+_cLista
      EndIf
      If !FWAlertYesNo("Confirma a exclusão deste investimento e seus sub-niveis? "+CRLF+_cLista,"ACOM00303")
         _lRet := .F.
         ZZI->(DBGoTo(_nRecAtual))
         Break
      EndIf
      If _lSoValida
         Break
      EndIf
      If Left(cZZI_TIPO,1) = "1"
         ZZI->(DBSetOrder(3))//ZZI_FILIAL+ZZI_INVPAI
         While ZZI->(DBSeek(xFilial() + cZZI_CODINV )) .And. ZZI->(!Eof())//LIMPA OS NIVEIS 2 E 3
	         ZZI->(RecLock("ZZI", .F.))
	         ZZI->(dbDelete())
	         ZZI->(MSUnLock())
         EndDo
      ElseIf Left(cZZI_TIPO,1) = "2"
         ZZI->(DBSetOrder(4))//ZZI_FILIAL+ZZI_NIVEL2
         While ZZI->(DBSeek(xFilial() + cZZI_CODINV )) .And. ZZI->(!Eof())//LIMPA OS NIVEIS 3
	         ZZI->(RecLock("ZZI", .F.))
	         ZZI->(dbDelete())
	         ZZI->(MSUnLock())
         EndDo
      EndIf
      ZZI->(DBGoTo(_nRecAtual))
	   ZZI->(RecLock("ZZI", .F.))
	   ZZI->(dbDelete())
	   ZZI->(MSUnLock())
	EndIf

End Sequence

If Select(_cAlias) > 0
   (_cAlias)->( DBCloseArea() )
EndIf

FWRestArea(_aArea)

Return _lRet

/*
===============================================================================================================================
Programa----------: ACOM003VLD
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 20/08/2015                                    .
Descrição---------: Função criada para fazer a validação da digitação das datas.
Parametros--------: Nenhum
Retorno-----------: Lógico - .T. dados válidas, .F. dados inválidos
===============================================================================================================================
*/
User Function ACOM003VLD()

Local _aArea	:= FWGetArea()
Local _lRet		:= .T.
Local _cCampo	:= ReadVar()

If 'ZZI_DTINIC' $ _cCampo
	If !(Empty(M->ZZI_DTFIM))
		If M->ZZI_DTINIC > M->ZZI_DTFIM
			FWAlertWarning("A data início não pode ser maior que a data final. Favor selecionar uma data válida.","ACOM00304")
			_lRet := .F.
		EndIf
	EndIf
ElseIf 'ZZI_DTFIM' $ _cCampo
	If !(Empty(M->ZZI_DTINIC))
		If M->ZZI_DTFIM < M->ZZI_DTINIC
			FWAlertWarning("A data final não pode ser menor que a data inicio. Favor selecionar uma data válida.","ACOM00305")
			_lRet := .F.
		EndIf
	EndIf
EndIf

FWRestArea(_aArea)

Return(_lRet)

/*
===============================================================================================================================
Programa----------: ACOM03Wrkf
Autor-------------: Alex Wallauer
Data da Criacao---: 03/01/2020
Descrição---------: Valida e Monta e envia email e Grava manual
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM03WRKF(_cChamada)

Local _aConfig	:= U_ITCFGEML('') , E , nInv //,nI
Local _cEmlLog	:= ""
Local _cMsgEml	:= ""
Local cGetPara	:= "sistema@italac.com.br"
Local cTit     := "INCLUSÃO DE INVESTIMENTO"
Local cGetAssun:= 'NOVO CADASTRO DE CENTRO DE INVESTIMENTO'
Local _lInclui := (_cChamada = "GRVI" )
Local _nRecAtual:= ZZI->(RECNO())
Local _lAmbTeste := !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento

If _cChamada == "VALGRV" 
   ZZL->(DBSetOrder(3)) //ZZL_FILIAL + ZZL_CODUSU
   If _lInclui .And. !ZZL->(DBSeek(xFilial("ZZL") + __cUserId))
   	FWAlertInfo("O usuário: " + cUserName + " não possui permissão para executar esta ação neste cadastro."+;
   		     "Verificar com a área de TI a possibilidade de habilitar o seu usuário.","ACOM00306")
   	Return .F.
   EndIf

   If M->ZZI_TIPO = "1" .And. (!Empty(M->ZZI_INVPAI) .Or. !Empty(M->ZZI_NIVEL2))
      FWAlertInfo("Campo Nivel 1 ou 2 Preenchidos Limpe os campos","ACOM00307")
      Return .F.
   EndIf
   Return .T.
EndIf

If _cChamada = "NIVEIS"//BOTAO Visualiza Niveis/Acerto
   If M->ZZI_TIPO = "1" 
      _cSelectN2:="SELECT R_E_C_N_O_ RECN2 FROM "+RETSQLNAME("ZZI")+" ZZI "
      _cSelectN2+="WHERE  D_E_L_E_T_ = ' ' AND ZZI_FILIAL = '"+xFilial("ZZI")+"' 
      _cSelectN2+=" AND ZZI_TIPO = '2' "
      _cSelectN2+=" AND ZZI_INVPAI = '"+M->ZZI_CODINV+"' "
   
      _cSelectN3:="SELECT R_E_C_N_O_ RECN3 FROM "+RETSQLNAME("ZZI")+" ZZI "
      _cSelectN3+="WHERE  D_E_L_E_T_ = ' ' AND ZZI_FILIAL = '"+xFilial("ZZI")+"' 
      _cSelectN3+=" AND ZZI_TIPO = '3' "
      _cSelectN3+=" AND ZZI_INVPAI = '"+M->ZZI_CODINV+"' "
      _cSelectN3+=" AND ZZI_NIVEL2 = '"//+ZZI->ZZI_CODINV+"' "

   Else
      _cSelectN2:="SELECT R_E_C_N_O_ RECN2 FROM "+RETSQLNAME("ZZI")+" ZZI "
      _cSelectN2+="WHERE  D_E_L_E_T_ = ' ' AND ZZI_FILIAL = '"+xFilial("ZZI")+"' 
      _cSelectN2+=" AND ZZI_TIPO = '3' "
      _cSelectN2+=" AND ZZI_NIVEL2 = '"+M->ZZI_CODINV+"' "  

   EndIf

   _cSelectN2 := ChangeQuery(_cSelectN2)
   MPSysOpenQuery(_cSelectN2,"TRBN2")
   
   TRBN2->(DBGoTop())

   _aDados:={}
   nTotN1GE:=0
   nTotN2GE:=0
   nTotN3GE:=0
   aLog:={}
   While !TRBN2->(Eof())
      ZZI->(DBGoTo(TRBN2->RECN2))

      If M->ZZI_TIPO = "1" 
         aAdd(aLog,{ZZI->ZZI_INVPAI , ZZI->ZZI_CODINV , Space(6), ZZI->ZZI_DESINV , "R$ "+AllTrim(Transform( ZZI->ZZI_VLRPRV ,"@E 999,999,999,999,999.99")),0, ZZI->ZZI_DTINIC,ZZI->ZZI_DTFIM })
         nTotN2GE:=ZZI->ZZI_VLRPRV 
         _nPosN2:=Len(aLog)
      
         dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cSelectN3+ZZI->ZZI_CODINV+"' " ) , "TRBN3" , .T., .F. )
         TRBN3->(DBGoTop())
         nTotN3GE:=0
         While !TRBN3->(Eof())
   
            ZZI->(DBGoTo(TRBN3->RECN3))
            aAdd(aLog,{ ZZI->ZZI_INVPAI , ZZI->ZZI_NIVEL2 , ZZI->ZZI_CODINV , ZZI->ZZI_DESINV , "R$ "+AllTrim(Transform( ZZI->ZZI_VLRPRV ,"@E 999,999,999,999,999.99")),0, ZZI->ZZI_DTINIC,ZZI->ZZI_DTFIM })
            nTotN3GE+=ZZI->ZZI_VLRPRV 
		      TRBN3->(DBSkip())
   
         EndDo
         TRBN3->(DBCloseArea())
         If nTotN3GE <> 0
            aLog[_nPosN2,6]:="R$ "+AllTrim(Transform( nTotN3GE ,"@E 999,999,999,999,999.99"))
            nTotN1GE+=nTotN3GE
         Else
            nTotN1GE+=nTotN2GE
         EndIf
      Else
         aAdd(aLog,{ ZZI->ZZI_INVPAI , ZZI->ZZI_NIVEL2 , ZZI->ZZI_CODINV , ZZI->ZZI_DESINV , "R$ "+AllTrim(Transform( ZZI->ZZI_VLRPRV ,"@E 999,999,999,999,999.99")),0, ZZI->ZZI_DTINIC,ZZI->ZZI_DTFIM })
         nTotN1GE+=ZZI->ZZI_VLRPRV 
      EndIf

      TRBN2->(DBSkip())
   EndDo
   TRBN2->(DBCloseArea())

   If Len(aLog) > 0
      If M->ZZI_TIPO = "1" 
         aAdd(aLog,{Space(6),"TOTAIS dos NIVEL 2", If(M->ZZI_VLRPRV<>nTotN1GE,"DIFERENTE do NIVEL 1","IGUAL ao NIVEL 1") ,M->ZZI_DESINV ,;
                 "R$ "+AllTrim(Transform( M->ZZI_VLRPRV ,"@E 999,999,999,999,999.99")),;
                 "R$ "+AllTrim(Transform( nTotN1GE      ,"@E 999,999,999,999,999.99")) , M->ZZI_DTINIC,M->ZZI_DTFIM })
      Else
         aAdd(aLog,{Space(6),"TOTAIS dos NIVEL 3", If(M->ZZI_VLRPRV<>nTotN1GE,"DIFERENTE do NIVEL 2","IGUAL ao NIVEL 2") ,M->ZZI_DESINV ,;
                 "R$ "+AllTrim(Transform( M->ZZI_VLRPRV ,"@E 999,999,999,999,999.99")),;
                 "R$ "+AllTrim(Transform( nTotN1GE      ,"@E 999,999,999,999,999.99")) , M->ZZI_DTINIC,M->ZZI_DTFIM })
      EndIf
      aCab:={}
      aAdd(aCab,"Cod.Nivel 1 ")
      aAdd(aCab,"Cod.Nivel 2 ")
      aAdd(aCab,"Cod.Nivel 3 ")
      aAdd(aCab,"Descricao do Nivel"  )
      aAdd(aCab,"Valor Previsto"      )
      aAdd(aCab,"Valor Previsto Total")
      aAdd(aCab,"Dt Inicio")
      aAdd(aCab,"Dt Fim"   )
      _cTitulo:='Lista de Investimentos por Nivel'
      _cMsgTop:=""
      If _cChamada == "NIVEIS"//BOTAO Visualiza Niveis/acerta
         _cMsgTop:="Clique no botão OK para fazer o acerto caso necessario"
      EndIf
                             //    , _aCols,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons )
      _lOK:=U_ITListBox(_cTitulo,aCab,aLog , .T.    , 1    ,_cMsgTop ,          ,        ,         ,     ,        , )
      If _lOK
         M->ZZI_VLRPRV:=nTotN1GE
      EndIf
   Else
      FWAlertInfo("Não foram encontrado niveis abaixo","ACOM00308")
   EndIf

   ZZI->(DBGoTo(_nRecAtual))
   
   Return .T.
EndIf

If (_cChamada = "BOTAO"  .Or. _cChamada $ "GRVA/GRVI")  .And. Left(M->ZZI_TIPO,1) $ "1,2"  
   _lRet:=.F.
   If _cChamada = "GRVI" 
      _lPergunta:=Len(_aDadosGrava) = 0
   ElseIf _cChamada = "GRVA" 
      If Left(M->ZZI_TIPO,1) = "1"
         ZZI->(DBSetOrder(3))//ZZI_FILIAL+ZZI_INVPAI
         _lPergunta:=Len(_aDadosGrava) = 0 .And. !ZZI->(DBSeek(xFilial() + M->ZZI_CODINV ))
      Else
         ZZI->(DBSetOrder(4))//ZZI_FILIAL+ZZI_NIVEL2
         _lPergunta:=Len(_aDadosGrava) = 0 .And. !ZZI->(DBSeek(xFilial() + M->ZZI_CODINV ))
      EndIf
   EndIf

   If _cChamada = "BOTAO" .OR.;
     (_lPergunta .And. FWAlertYesNo("Deseja vincular niveis "+AllTrim(Str(Val(M->ZZI_TIPO)+1))+" a esse investimento ?","ACOM00309"))

      _cSelect:="SELECT ZZI_CODINV , ZZI_DESINV FROM "+RETSQLNAME("ZZI")+" ZZI "
      _cSelect+="WHERE  D_E_L_E_T_ = ' ' AND ZZI_FILIAL = '"+xFilial("ZZI")+"' 
	  
      MV_PAR01:=""
	   If Left(M->ZZI_TIPO,1) = "1"
	      _cSelect+=" AND ZZI_TIPO   = '2' "
	      _cSelect+=" AND ZZI_INVPAI = ' ' "//"+M->ZZI_INVPAI+"
	      _cSelect+=" AND ZZI_NIVEL2 = ' ' "         
         _cTitulo:='Lista de Investimentos do Nivel 2 e 3'
	   
      ElseIf Left(M->ZZI_TIPO,1) = "2"
	      _cSelect+=" AND ZZI_TIPO   =  '3' "
	      _cSelect+=" AND ZZI_INVPAI =  ' ' "
	      _cSelect+=" AND ZZI_NIVEL2 =  ' ' "
         _cTitulo:='Lista de Investimentos do Nivel 3'

	   EndIf

      _cSelect+=" ORDER BY ZZI_CODINV " 
      //                 1           2         3                                 4                    5          6          7         8          9         10         11        12
      //             _cNomeSXB , _cTabela ,_nCpoChave                , _nCpoDesc                , _bCondTab , _cTitAux, _nTamChv , _aDados , _nMaxSel , _lFilAtual , _cMVRET , _bValida , _oProc , _aParam
	   _lRet:=U_ITF3GEN(        ,_cSelect  ,{|Tab| (Tab)->ZZI_CODINV },{|Tab| (Tab)->ZZI_DESINV },           , _cTitulo,          ,         ,          , .T.        , "MV_PAR01")
      _lRet2:=.F.
   	aLog:={}
	   If _lRet .And. !Empty(MV_PAR01)
	   	_aDados := StrTokArr(MV_PAR01, ';')
	   	For nInv := 1 TO Len(_aDados)
            ZZI->(DBSetOrder(1))//ZDA_FILIAL+ZZI_CODINV
	         If ZZI->(DBSeek(xFilial() + _aDados[nInv] ))
               aAdd(aLog,{.T.,.F.,ZZI->ZZI_CODINV , Space(6) , ZZI->ZZI_DESINV, "R$ "+AllTrim(Transform( ZZI->ZZI_VLRPRV ,"@E 999,999,999,999,999.99")), ZZI->ZZI_DTINIC, ZZI->ZZI_DTFIM })
	         EndIf
            If Left(M->ZZI_TIPO,1) = "1"
               ZZI->(DBSetOrder(4))//ZDA_FILIAL+M->ZZI_NIVEL2
               If ZZI->(DBSeek(xFilial() + _aDados[nInv] ))
                  While ZZI->(!Eof()) .And. xFilial("ZZI")+_aDados[nInv] == ZZI->ZZI_FILIAL+ZZI->ZZI_NIVEL2
                     aAdd(aLog,{.T.,.T.,ZZI->ZZI_NIVEL2 , ZZI->ZZI_CODINV , ZZI->ZZI_DESINV, "R$ "+AllTrim(Transform( ZZI->ZZI_VLRPRV ,"@E 999,999,999,999,999.99")), ZZI->ZZI_DTINIC, ZZI->ZZI_DTFIM})
                     ZZI->(DBSkip())
                  EndDo        
               EndIf		
            EndIf		
         Next
	   	_lRet2:=.T.//LIGA LIGA PQ O TIPO = 2 NÃO TEM SEGUNDA TELA
         If Left(M->ZZI_TIPO,1) = "1"
            If Len(aLog) > 0 
               aCab:={}
               aAdd(aCab," ")
               aAdd(aCab," ")
               aAdd(aCab,"Cod.Nivel 2" )
               aAdd(aCab,"Cod.Nivel 3" )
               aAdd(aCab,"Descricao"   )
               aAdd(aCab,"Valor Previsto")
               aAdd(aCab,"Dt Inicio"   )
               aAdd(aCab,"Dt Fim"      )
	            _cTitulo:='Lista de Investimentos Selecionados'
               bCondMarca:={|oLbxAux,nAt| oLbxAux:aArray[nAt][2] }
               _cMsgTop:="Clique em OK para confirmar a seleções dos niveis (Todos os niveis 3 serão selecinados)"//(Marque pelo menos 1 nivel 3 p/ cada nivel 2)"
                                           //  , _aCols,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk , _aColXML , bCondMarca )
               _lRet2:=U_ITListBox(_cTitulo,aCab,aLog   , .T.    , 2    ,_cMsgTop,          ,        ,         ,     ,        ,          ,       ,         ,          , bCondMarca)
	         ElseIf Left(M->ZZI_TIPO,1) = "1"
	            FWAlertWarning("Não foram criados novos registros",'ACOM00310')
               _lRet2:=.F.
	         EndIf
         EndIf
	   EndIf
      ZZI->(DBGoTo(_nRecAtual))
	   If _lRet2
         _aDadosGrava:=ACLONE(aLog)
         If _cChamada <> "BOTAO"
            ACOM03GRV(_cChamada)//Grava os niveis         
         EndIf         
	   EndIf
   EndIf
EndIf

If Len(_aDadosGrava) > 0 .And. _cChamada $ "GRVA/GRVI" .And. Left(M->ZZI_TIPO,1) $ "1,2"  
   ACOM03GRV(_cChamada)//Grava os niveis         
EndIf         

If _cChamada $ "GRVA/GRVI" .And. Left(M->ZZI_TIPO,1) $ "1,2" //SÓ ALTERA E INCLUI DOS TIPOS 1 e 2 
   If Left(M->ZZI_TIPO,1) = "1" 
      ZZI->(DBGoTo(_nRecAtual))
      If _cChamada = "GRVI"//INCLUSAO TEM QUE TRAVAR
         ZZI->(RecLock("ZZI",.F.)) 
         ZZI->ZZI_CHAVE:= M->ZZI_CHAVE:= M->ZZI_CODINV//GRAVA AQUI NOS CASO QUE NÃO VINCULOU NADA NA INCLUSAO
         ZZI->(MSUnLock()) 
      Else
         ZZI->ZZI_CHAVE:= M->ZZI_CHAVE:= M->ZZI_CODINV//GRAVA AQUI NOS CASO QUE NÃO VINCULOU NADA NA ALTERECAO
      EndIf
      
      If M->ZZI_MSBLQL = "1"// SÓ REPASSA PARA OS DESMAIS SE For PARA BLOQUEAR , PQ SENÃO SOBREPOE OS BLOQUEADOS INDIVIDUAIS
         ZZI->(DBSetOrder(3))//ZZI_FILIAL+ZZI_INVPAI
         If ZZI->(DBSeek(xFilial() + M->ZZI_CODINV ))
            While ZZI->(!Eof()) .And. xFilial("ZZI")+M->ZZI_CODINV == ZZI->ZZI_FILIAL+ZZI->ZZI_INVPAI
               ZZI->(RecLock("ZZI",.F.)) 
               ZZI->ZZI_MSBLQL := M->ZZI_MSBLQL
               ZZI->(MSUnLock()) 
               ZZI->(DBSkip())
            EndDo        
         EndIf
      EndIf
   ElseIf Left(M->ZZI_TIPO,1) = "2" .And. M->ZZI_MSBLQL = "1"// SÓ REPASSA PARA OS DESMAIS SE For PARA BLOQUEAR , PQ SENÃO SOBREPOE OS BLOQUEADOS INDIVIDUAIS
      ZZI->(DBSetOrder(4))//ZDA_FILIAL+M->ZZI_NIVEL2
      If ZZI->(DBSeek(xFilial() + M->ZZI_CODINV  ))
         While ZZI->(!Eof()) .And. xFilial("ZZI")+M->ZZI_CODINV  == ZZI->ZZI_FILIAL+ZZI->ZZI_NIVEL2
            ZZI->(RecLock("ZZI",.F.)) 
            ZZI->ZZI_MSBLQL := M->ZZI_MSBLQL
            ZZI->(MSUnLock()) 
            ZZI->(DBSkip())
         EndDo        
      EndIf		
   EndIf
EndIf         

If M->ZZI_TIPO $ "2,3"  .Or. _cChamada $ "BOTAO/NIVEIS/GRVA"//Não envia e-mail quando For subs e não é inclusao
	Return .T.	    
EndIf

//ENVIA E-MAIL SÓ NA INCLUSAO (_cChamada=GRVI) E M->ZZI_TIPO = 1

_cQry := "SELECT ZZL_EMAIL "
_cQry += "FROM " + RetSqlName("ZZL") + " "
_cQry += "WHERE ZZL_FILIAL = '" + xFilial("ZZL") + "' "
_cQry += "  AND ZZL_ENVINV  = 'S' AND ZZL_FILWEP LIKE '%"+cFilant+"%'"
_cQry += "  AND D_E_L_E_T_ = ' ' "
_cQry := ChangeQuery(_cQry)
MPSysOpenQuery(_cQry,"TRBZZL")

TRBZZL->(DBGoTop())

_acTo:={}
While !TRBZZL->(Eof())
	aAdd(_acTo,AllTrim(TRBZZL->ZZL_EMAIL))
	TRBZZL->(DBSkip())
EndDo
TRBZZL->(DBCloseArea())

_cMsgEml := '<html>'
_cMsgEml += '<head><title>'+cTit+'</title></head>'
_cMsgEml += '<body>'
_cMsgEml += '<style Type="text/css"><!--'
_cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
_cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
_cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-Left: 15px; background-color: #C6E2FF; }'
_cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-Left: 15px; background-color: #E5E5E5; }'
_cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-Left: 15px; background-color: #FFFFFF; }'
_cMsgEml += '--></style>'
_cMsgEml += '<center>'
_cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="900" height="50"><br>'
_cMsgEml += '<table class="bordasimples" width="900">'
_cMsgEml += '    <tr>'
_cMsgEml += '	     <td class="titulos"><center>'+cTit+'</center></td>'
_cMsgEml += '	 </tr>'
_cMsgEml += '</table>'
_cMsgEml += '<br>'
_cMsgEml += '<table class="bordasimples" width="900">'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td align="center" colspan="2" class="grupos">Dados do Investimento</b></td>'
_cMsgEml += '    </tr>'

_cPer:="18"

_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="Left" width="'+_cPer+'%"><b>Usuario:</b></td>'
_cMsgEml += '      <td class="itens" >'+ UsrFullName(__cUserId) +'</td>'
_cMsgEml += '    </tr>'

_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="Left" width="'+_cPer+'%"><b>Codigo:</b></td>'
_cMsgEml += '      <td class="itens" >'+ M->ZZI_CODINV +'</td>' 
_cMsgEml += '    </tr>'

_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="Left" width="'+_cPer+'%"><b>Descricao:</b></td>'
_cMsgEml += '      <td class="itens" >'+ M->ZZI_DESINV +'</td>' 
_cMsgEml += '    </tr>'

_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="Left" width="'+_cPer+'%"><b>Data Inclusao:</b></td>'
_cMsgEml += '      <td class="itens" >'+DToC(DATE())+'</td>'
_cMsgEml += '    </tr>'

_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="Left" width="'+_cPer+'%"><b>Data Inicio:</b></td>'
_cMsgEml += '      <td class="itens" >'+DToC(M->ZZI_DTINIC)+'</td>'
_cMsgEml += '    </tr>'

_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="Left" width="'+_cPer+'%"><b>Data Fim:</b></td>'
_cMsgEml += '      <td class="itens" >'+DToC(M->ZZI_DTFIM)+'</td>'
_cMsgEml += '    </tr>'

_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="Left" width="'+_cPer+'%"><b>Observacao:</b></td>'
_cMsgEml += '      <td class="itens" >'+AllTrim(M->ZZI_OBS)+'</td>'
_cMsgEml += '    </tr>'


_cMsgEml += '</table>'
_cMsgEml += '</center>'
_cMsgEml += '<br>'
_cMsgEml += '<br>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="Left" ><b>Ambiente:</b></td>'
_cMsgEml += '      <td class="itens" align="Left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [ACOM003]</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '</body>'
_cMsgEml += '</html>'

For E := 1 TO Len(_acTo)
    cGetPara:=_acTo[E]
    // Chama a função para envio do e-mail
//    ITEnvMail(cFrom        ,cEmailTo,_cEmailCo,cEmailBcc,cAssunto ,cMensagem,cAttach   ,cAccount    ,cPassword   ,cServer     ,cPortCon    ,lRelauth     ,cUserAut     ,cPassAut     ,cLogErro)
    U_ITENVMAIL(_aConfig[01], cGetPara,         ,         ,cGetAssun,_cMsgEml ,          ,_aConfig[01],_aConfig[02],_aConfig[03],_aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )
		
    If _lAmbTeste
       FWAlertSuccess(Upper(_cEmlLog)+CHR(13)+CHR(10)+"E-mail para: "+cGetPara,"ACOM00311")
    EndIf
Next E

Return .T.

/*
===============================================================================================================================
Programa----------: ACOM03GRV
Autor-------------: Alex Wallauer
Data da Criacao---: 03/01/2021
Descrição---------: Valida e Monta e envia email e Grava manual
Parametros--------: _cChamada
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ACOM03GRV(_cChamada)

Local _cCod1    := Space(6)
Local _cCod2    := Space(6)
Local _cCod3    := Space(6)
Local _aLog     := {}
Local _aTotN1   := {}
Local nInv:=nTot:= 0 , A
Local _nRecAtual:= ZZI->(RECNO())
Local nTotN1GE  := 0
Local nTotN2GE  := 0
Local aAcertoN2 := {}
Local lAcertaN2 := .F.

For nInv := 1 TO Len(_aDadosGrava)
   If !_aDadosGrava[nInv][01]
      lAcertaN2:=.T.
      Loop
   EndIf
   
   ZZI->(DBSetOrder(1))//ZDA_FILIAL+ZZI_CODINV
   If !Empty(_aDadosGrava[nInv][4])
      If !ZZI->(DBSeek(xFilial() + AllTrim(_aDadosGrava[nInv][4]) ))//SEEK NO NIVEL 3
         Loop
      EndIf
   Else
      If !ZZI->(DBSeek(xFilial() + AllTrim(_aDadosGrava[nInv][3]) ))//SEEK NO NIVEL 4
         Loop
      EndIf
   EndIf
   
   _cCod1  := Space(6)
   _cCod2  := Space(6)
   _cCod3  := Space(6)
   _cCod1D := ""
   _cCod2D := ""
   _cDesc  := ZZI->ZZI_DESINV//Descrição cadastrada atual
   _cTipo  := ZZI->ZZI_TIPO  //TIPO DO NIVEL PROSICIONADO
   _nValor := ZZI->ZZI_VLRPRV
	_cCod   := GetSXENum("ZZI","ZZI_CODINV")//Codigo novo 
   
   If _cTipo = "2"//TIPO DO NIVEL PROSICIONADO
      _cCod1 := M->ZZI_CODINV //COD NIVEL 1 ATUAL
      _cCod1D:= M->ZZI_DESINV //DESC NIVEL 1 ATUAL
      If aScan(_aTotN1, {|T| T[1]== ZZI->ZZI_CODINV }) = 0
         //Total      {Cod. N2        ,Vlr N2         ,Vlr N3,Cod. N2 Novo}
         aAdd(_aTotN1,{ZZI->ZZI_CODINV,ZZI->ZZI_VLRPRV,0     ,_cCod       ,_cDesc})//GRAVA DADOS PARA USAR NOS NIVEIS 3 DO NIVEL 2 ATUAL
      EndIf
   
   ElseIf _cTipo = "3"//TIPO DO NIVEL PROSICIONADO
      If Left(M->ZZI_TIPO,1) = "1" // SÓ NO CADASTRO NIVEL 1 // TIPO DO NIVEL DO CADASTRO ATUAL
         _cCod1  := M->ZZI_CODINV  // COD NIVEL 1 ATUAL
         _cCod1D := M->ZZI_DESINV  // DESC NIVEL 1 ATUAL
         If (nTot:= aScan(_aTotN1, {|T| T[1]== ZZI->ZZI_NIVEL2 })) <> 0
            _aTotN1[nTot,3]+=ZZI->ZZI_VLRPRV//SOMA DO NIVEL 1     
            _cCod2 := _aTotN1[nTot,4]//Pega Codigo novo do nivel 2
            _cCod2D:= _aTotN1[nTot,5]//Pega descricao do nivel 2
         EndIf

      ElseIf Left(M->ZZI_TIPO,1) = "2"// SÓ NO CADASTRO NIVEL 2  // TIPO DO NIVEL DO CADASTRO ATUAL
         _cCod1  := M->ZZI_INVPAI     // Pega Codigo do nivel 1 se tiver no N2
         _cCod1D := M->ZZI_DESINV     // DESC NIVEL 1 ATUAL
         _cCod2  := M->ZZI_CODINV     // COD NIVEL 2 ATUAL
         _cCod2D := M->ZZI_DESINV     // DESCRICAO DI N2 ATUAL
         nTotN2GE+= ZZI->ZZI_VLRPRV   // TOTAL DO NIVEL 3 NO CADASTRO DO NIVEL 2
      
      EndIf
      _cCod3:=_cCod //Codigo novo do nivel 3 NOVO
   
   EndIf   
	ZZI->(RecLock("ZZI",.T.))
	ZZI->ZZI_FILIAL := xFilial("ZZI")
	ZZI->ZZI_CODINV := _cCod
   ZZI->ZZI_INVPAI := _cCod1
   ZZI->ZZI_NIVE1D := _cCod1D
   ZZI->ZZI_NIVEL2 := _cCod2
   ZZI->ZZI_NIVE2D := _cCod2D
	ZZI->ZZI_DESINV := _cDesc
	ZZI->ZZI_TIPO   := _cTipo
   ZZI->ZZI_VLRPRV := _nValor
	ZZI->ZZI_DTINIC := M->ZZI_DTINIC
	ZZI->ZZI_DTFIM  := M->ZZI_DTFIM
	ZZI->ZZI_OBS    := M->ZZI_OBS   
	ZZI->ZZI_MSBLQL := M->ZZI_MSBLQL
   If M->ZZI_TIPO = "1"// Inclusao do NIVEL 1
      If _cTipo = "2"  // Inclusao do NIVEL 2 no NIVEL 1
         ZZI->ZZI_CHAVE  := _cCod1+_cCod
         aAdd(aAcertoN2,{ ZZI->ZZI_CHAVE,0,ZZI->(RECNO()),ZZI->ZZI_CODINV})
      Else             // Inclusao do NIVEL 3 no NIVEL 1
         ZZI->ZZI_CHAVE  := _cCod1+_cCod2+_cCod3
         If (nPos:=aScan(aAcertoN2,{|A| A[1]= ZZI->ZZI_INVPAI+ZZI->ZZI_NIVEL2 } ))  <> 0
             aAcertoN2[nPos,2]+=_nValor
         EndIf
      EndIf
   ElseIf M->ZZI_TIPO = "2"         // Inclusao do NIVEL 2 que pode ter ou não vin
      ZZI->ZZI_CHAVE := AllTrim(_cCod1)+_cCod2+_cCod// Inclusao do NIVEL 3 no NIVEL 2
   EndIf
   ZZI->(MSUnLock())
	ConfirmSX8() 
   If _cTipo = "2"//ATUALIA PARA O CODIGO NOVO GERADO
      _cCod2:=_cCod
   EndIf
	aAdd(_aLog,{_cCod1,_cCod2, _cCod3 , ZZI->ZZI_DESINV, ZZI->ZZI_DTINIC, ZZI->ZZI_DTFIM , "R$ "+AllTrim(Transform( _nValor ,"@E 999,999,999,999,999.99")),ZZI->ZZI_CHAVE })
//                1      2        3            4               5               6                                      7                                            8
Next

ZZI->(DBGoTo(_nRecAtual))//POSICIONA DE VOLTA NO NIVEL DO CADASTRO PARA ACERTO
If ZZI->ZZI_TIPO = "1" 
   For nTot := 1 TO Len(_aTotN1)
       If _aTotN1[nTot,3] > 0 
          nTotN1GE+=_aTotN1[nTot,3]
       Else
          nTotN1GE+=_aTotN1[nTot,2]
       EndIf
   Next
   M->ZZI_VLRPRV:=(M->ZZI_VLRPRV+nTotN1GE)
   If lAcertaN2
      For A := 1 TO Len(aAcertoN2)
          ZZI->(DBGoTo(aAcertoN2[A,3]))//POSICIONA NIVEL 2 PARA ACERTAR O VALOR COM A SOMATORIA DO N3
          ZZI->(RecLock("ZZI",.F.)) 
          ZZI->ZZI_VLRPRV := aAcertoN2[A,2]
          ZZI->(MSUnLock()) 
          If (nPos:=aScan(_aLog,{|L| L[8] == aAcertoN2[A,1] } )) <> 0 
              _aLog[nPos,7]:="R$ "+AllTrim(Transform( aAcertoN2[A,2] ,"@E 999,999,999,999,999.99"))
          EndIf          
      Next
      ZZI->(DBGoTo(_nRecAtual))//POSICIONA DE VOLTA NO NIVEL DO CADASTRO ATUAL PARA ACERTO
   EndIf

ElseIf ZZI->ZZI_TIPO = "2" 
   M->ZZI_VLRPRV:=(M->ZZI_VLRPRV+nTotN2GE)
EndIf
If _cChamada = "GRVI"//INCLUSAO TEM QUE TRAVAR
   ZZI->(MSUnLock()) //Por garantia
   ZZI->(RecLock("ZZI",.F.)) // não tá travado na inclusao as vezes
   ZZI->ZZI_VLRPRV := M->ZZI_VLRPRV
   If ZZI->ZZI_TIPO $ "1,2" // N1 E N2
      ZZI->ZZI_CHAVE  := ZZI->ZZI_CODINV
   EndIf
   ZZI->(MSUnLock()) 
ElseIf _cChamada = "GRVA"//ALTERACAO NÃO PRECISA TRAVAR
   ZZI->ZZI_VLRPRV := M->ZZI_VLRPRV
   If M->ZZI_TIPO = "2" // quando vincula N3 NO N2
      ZZI->ZZI_CHAVE:= M->ZZI_CODINV
   EndIf
EndIf

If Len(_aLog) > 0
   aCab:={}
   aAdd(aCab,"Cod.Nivel 1")
   aAdd(aCab,"Cod.Nivel 2")
   aAdd(aCab,"Cod.Nivel 3")
   aAdd(aCab,"Descricao")
   aAdd(aCab,"Dt Inicio")
   aAdd(aCab,"Dt Fim")
   aAdd(aCab,"Valor Previsto")
   aAdd(aCab,"Chave Ordenacao")
   _cTitulo:='Lista dos Investimentos Vinculados com sucesso'
                           //, _aCols,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons )
   U_ITListBox(_cTitulo,aCab,_aLog   , .T.    , 1    ,       ,          ,        ,         ,     ,        , )
Else
   FWAlertInfo("Nao houve alteracoes nos sub-niveis","ACOM01012")
EndIf
_aDadosGrava:={}//Limpa a variavel Private para prevenir duplicidade

Return .T.

/*
===============================================================================================================================
Programa--------: ACOM03Tela()
Autor-----------: Alex Walaluer
Data da Criacao-: 29/03/2021
Descrição-------: Tela de capa e detalhe
Parametros------:  cAlias ; _nOpc ; nReg
Retorno---------: .T.
===============================================================================================================================
*/
Static Function ACOM03Tela(cAlias,_nRec,_nOpc,_aBotoes)//cAlias,nReg,nOpc

Local aDarGets		 := NIL
Local aCamposMostra:= {}
Local aTB_Campos	 := {}
Local _aCamposTrb  := {}
Local aSemSX3		 := { {"TRBF_OK","C",02,0} , {"REC_ZZI","N",10,0}  }
Local _bOk := {|| U_ACOM03Wrkf("VALGRV")}
Local I,_nI, _nRegAtu 

Private  aHeader:= {}
Private cAliasWK:= GetNextAlias()
Private cMarca  := GetMark()
Private oEnCh1, oMark, oDlg

If Select(cAliasWK) # 0
   (cAliasWK)->(DBCloseArea())
EndIf
aAdd(aCamposMostra,"NOUSER")
DBSelectArea(cAlias)
For i := 1 To FCount()
   If Left(ZZI->ZZI_TIPO,1) = "1" .And. FieldName(i) $ "ZZI_NIVEL2/ZZI_NIVE2D/ZZI_NIVE1D/ZZI_INVPAI"
      Loop
   ElseIf Left(ZZI->ZZI_TIPO,1) = "2" .And. FieldName(i) $ "ZZI_NIVEL2/ZZI_NIVE2D"
      Loop
   EndIf
    M->&(FieldName(i)) := FieldGet(i)
    aAdd(aCamposMostra,FieldName(i))
Next 

aAdd(_aCamposTrb, "ZZI_TIPO  ")
aAdd(_aCamposTrb, "ZZI_CODINV")
aAdd(_aCamposTrb, "ZZI_DESINV")   
aAdd(_aCamposTrb, "ZZI_NIVEL2")
aAdd(_aCamposTrb, "ZZI_NIVE2D")
aAdd(_aCamposTrb, "ZZI_VLRPRV")  
aAdd(_aCamposTrb, "ZZI_DTINIC")  
aAdd(_aCamposTrb, "ZZI_DTFIM")   
aAdd(_aCamposTrb, "ZZI_CHAVE")  
aAdd(_aCamposTrb, "ZZI_MSBLQL")  
   
// Monta aHeader e a estrutura da tabela temporária.
SX3->(DBSetOrder(2)) // X3_CAMPO
DBSelectArea("SX3")

aAdd( aTB_Campos , { "TRBF_OK",,"",} )

For _nI := 1 To Len(_aCamposTrb)
    aAdd(aHeader,{Trim(Getsx3cache(_aCamposTrb[_nI],"X3_TITULO")),;                      
                       _aCamposTrb[_nI],;                      
                       Getsx3cache(_aCamposTrb[_nI],"X3_PICTURE"),;                      
                       Getsx3cache(_aCamposTrb[_nI],"X3_TAMANHO"),;
                       Getsx3cache(_aCamposTrb[_nI],"X3_DECIMAL"),;                      
                       Getsx3cache(_aCamposTrb[_nI],"X3_VALID"  ),;                      
                                      "",;                      
                       Getsx3cache(_aCamposTrb[_nI],"X3_TIPO"   ),;                      
                                      "",;                      
                                      "" })
    aAdd(aSemSX3, {_aCamposTrb[_nI],;                      
                    Getsx3cache(_aCamposTrb[_nI],"X3_TIPO"),;                      
                    Getsx3cache(_aCamposTrb[_nI],"X3_TAMANHO"),;                   
                    Getsx3cache(_aCamposTrb[_nI],"X3_DECIMAL")})	

    If _aCamposTrb[_nI] $ "ZZI_NIVEL2/ZZI_NIVE2D"
       Loop
    EndIf

    If _aCamposTrb[_nI] = "ZZI_TIPO"
       aAdd(aTB_Campos,{{|| If((cAliasWK)->ZZI_TIPO="1","Investimento Nivel 1",If((cAliasWK)->ZZI_TIPO="2",;
                                                      "Investimento Nivel 2",;
                                                      "Investimento Nivel 3")) },,"Tipo",;
                                                      ""})
    Else
       aAdd(aTB_Campos,{_aCamposTrb[_nI],,Trim(Getsx3cache(_aCamposTrb[_nI],"X3_TITULO")),;
                                               Getsx3cache(_aCamposTrb[_nI],"X3_PICTURE")})
    EndIf
Next
_oTemp:= FWTemporaryTable():New( cAliasWK, aSemSX3 )

If Left(M->ZZI_TIPO,1) = "1"
   _oTemp:AddIndex( "01", {"ZZI_CHAVE","ZZI_NIVEL2","ZZI_CODINV"} )
   _oTemp:AddIndex( "02", {"ZZI_CODINV"} )
Else
   _oTemp:AddIndex( "01", {"ZZI_CODINV"} )
EndIf

_oTemp:Create()

If _nOpc <> 2
   aDarGets:= NIL 
ElseIf _nOpc = 2 // VISUAL
   _bOk    := {|| .T.}
   aDarGets:= {}
EndIf

If Left(M->ZZI_TIPO,1) = "1"
   ZZI->(DBSetOrder(3))//ZZI_FILIAL+ZZI_INVPAI
   If ZZI->(DBSeek(xFilial() + M->ZZI_CODINV ))
      While ZZI->(!Eof()) .And. xFilial("ZZI")+M->ZZI_CODINV == ZZI->ZZI_FILIAL+ZZI->ZZI_INVPAI
		   (cAliasWK)->(DBAPPEND())
         AVREPLACE("ZZI",cAliasWK)
         (cAliasWK)->REC_ZZI:=ZZI->(RECNO())
         ZZI->(DBSkip())
      EndDo        
   EndIf
ElseIf Left(M->ZZI_TIPO,1) = "2"
   ZZI->(DBSetOrder(4))//ZDA_FILIAL+M->ZZI_NIVEL2
   If ZZI->(DBSeek(xFilial() + M->ZZI_CODINV  ))
      While ZZI->(!Eof()) .And. xFilial("ZZI")+M->ZZI_CODINV  == ZZI->ZZI_FILIAL+ZZI->ZZI_NIVEL2
		   (cAliasWK)->(DBAPPEND())
         AVREPLACE("ZZI",cAliasWK)
         (cAliasWK)->REC_ZZI:=ZZI->(RECNO())
         ZZI->(DBSkip())
      EndDo        
   EndIf		
EndIf

_aCores := {}
aAdd(_aCores,{"(cAliasWK)->ZZI_MSBLQL == '1'","BR_VERMELHO"})   
aAdd(_aCores,{"(cAliasWK)->ZZI_TIPO   == '2'","BR_AZUL"    })
aAdd(_aCores,{"(cAliasWK)->ZZI_TIPO   == '3'","BR_AMARELO" })
aAdd(_aCores,{"(cAliasWK)->ZZI_TIPO   == ' '","BR_PRETO"   })

While .T.
	nOpca:=0
	aCoors:= FWGetDialogSize(oMainWnd)
	oMainWnd:ReadClientCoords()//So precisa declarar uma fez para o Programa todo
	Define MSDialog oDlg Title "Cadastro de Investimentos" From aCoors[1],aCoors[2] To aCoors[3],aCoors[4] OF oMainWnd Pixel
		nLinha :=Int(((oMainWnd:nBottom-60)-(oMainWnd:nTop+125))/2.5)-50

		(cAlias)->(DBGoTo(_nRec))
		//MsmGet(): New (   [ cAlias], uPar2,nOpc>,,,, [ aAcho]    , [ aPos]                             ,[ aCpos],nModelo, [ uPar11], [ uPar12], [ uPar13], [ oWnd], [ lF3], [ lMemoria], [ lColumn], [ caTela], [ lNoFolder], [ lProperty], [ aField], [ aFolder], [ lCreate], [ lNoMDIStretch], [ uPar25] )																												,,,,,,,   ,,.T.)
		oEnCh1:=MsMget():New( cAlias ,_nRec ,_nOpc,,,,aCamposMostra,{15,1,nLinha,(oDlg:nClientWidth-4)/2},aDarGets,1      )  

		(cAliasWK)->(DBGoTop())
		oMark:=MSSELECT():New(cAliasWK,"TRBF_OK","ZZI_TIPO =' '",aTB_Campos,.F.,@cMarca,{nLinha+1,1,(oDlg:nClientHeight-6)/2,(oDlg:nClientWidth-4)/2},,,,,_aCores)
   	oMark:bMark := {|| ACOM03Mark(oMark,cAliasWK,oEnCh1)}
       
	Activate MSDialog oDlg ON INIT ( EnchoiceBar(oDlg, {|| If(Eval(_bOk),(nOpca:=1,oDlg:End()),) } ,;
                                                      {|| (nOpca:=0,oDlg:End()) },,_aBotoes) ,;
                                    oEnCh1:oBox:Align:=CONTROL_ALIGN_TOP ,;
                                    oMark:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT ,;
                                    oMark:oBrowse:Refresh() )
	If nOpca = 1 .And. _nOpc <> 2
      //  Atualizar aqui a Work.
      
      If _nOpc == 4
         _nRegAtu := ZZI->(Recno())

         (cAliasWK)->(DBGoTop())
         While ! (cAliasWK)->(Eof())
            ZZI->(DBGoTo((cAliasWK)->REC_ZZI))

            ZZI->(RecLock("ZZI",.F.))
            ZZI->ZZI_DTINIC := (cAliasWK)->ZZI_DTINIC
            ZZI->ZZI_DTFIM  := (cAliasWK)->ZZI_DTFIM
            ZZI->(MSUnLock())

            (cAliasWK)->(DBSkip())
         EndDo 

         ZZI->(DBGoTo(_nRegAtu))
      EndIf 

      ZZI->(RecLock("ZZI",.F.)) 
      AVREPLACE("M", "ZZI") 
	   If U_ACOM03Wrkf("GRVA")
         ZZI->(MSUnLock()) 
			Exit
      EndIf
      ZZI->(MSUnLock()) 
		If Select(cAliasWK) # 0
			Loop
		Else//Se o TRB For fechado erroniamente
			Exit
		EndIf         
	EndIf

	Exit

EndDo

If Select(cAliasWK) # 0
   _otemp:delete()
EndIf

Return .T.               

/*
===============================================================================================================================
Programa--------: ACOM03Tela()
Autor-----------: Alex Walaluer
Data da Criacao-: 29/03/2021
Descrição-------: Tela de capa e detalhe
Parametros------:  oMark,cAliasWK,oEnCh1
Retorno---------: .T.
===============================================================================================================================
*/
Static Function ACOM03Mark(oMark,cAliasWK,oEnCh1)

Local _oDlg
Local _nOpcao   := 00
Local _nLinha   := 05
Local _nPula    := 20
Local _nTam     := 50
Local _nCol1    := 10
Local _nCol2    := _nCol1+40
Local _cTit	    := "ALTERA OU EXCLUI LINHA DO INVENSTIMENTO"
Local _bValid   := {|| If(_dDT_Fim >= _dDT_Ini,.T.,(FWAlertInfo("Periodo inválido. Tente novamente com outro periodo","ACOM00312"),.F.) ) }
Local _bOK      := {|| (If(EVAL(_bValid) ,(_nOpcao:=1,_oDlg:End()),))  }
Local _cInv     := (cAliasWK)->ZZI_CODINV+" - "+AllTrim((cAliasWK)->ZZI_DESINV)
Local _cCodigo  := (cAliasWK)->ZZI_CODINV//CODIGO DA LINHA ATUAL
Local _cNivel2  := (cAliasWK)->ZZI_NIVEL2
Local _nRecAtuWR:= (cAliasWK)->(RECNO())
Local _nRecAtual:= ZZI->(RECNO())

Private _nValor := (cAliasWK)->ZZI_VLRPRV
Private _dDT_Ini:= (cAliasWK)->ZZI_DTINIC 
Private _dDT_Fim:= (cAliasWK)->ZZI_DTFIM
Private _cBloq  := (cAliasWK)->ZZI_MSBLQL

While .T.
   _lOK   := .F.
   _nLinha:= 05

   Define MSDialog _oDlg Title _cTit From 000,000 To 280,480 Pixel
   
    @ _nLinha,_nCol1       Button "Gravar Alteracao" Size 55,15 Action (EVAL(_bOK)) OF _oDlg Pixel
    @ _nLinha,(_nCol1+060) Button "Excluir Linha"    Size 55,15 Action (_nOpcao:=2,_oDlg:End()) OF _oDlg Pixel
    @ _nLinha,(_nCol1+120) Button "CANCELAR"         Size 55,15 Action (_nOpcao:=0,_oDlg:End()) OF _oDlg Pixel
      _nLinha+=_nPula
					
    @ _nLinha, _nCol1 Say "Investimento" SIZE 160,010  OF _oDlg PIXEL 
    @ _nLinha, _nCol2 MSGET _cInv  PICTURE "@!" SIZE 140,008 OF _oDlg PIXEL WHEN .F.
      _nLinha+=_nPula

    @ _nLinha+1, _nCol1 Say "Valor Previsto" SIZE 060,010  OF _oDlg PIXEL 
    @ _nLinha  , _nCol2 MSGET _nValor  PICTURE PesqPict("ZZI","ZZI_VLRPRV") SIZE _nTam,008 OF _oDlg PIXEL VALID (NaoVazio(_nValor) .And. Positivo(_nValor)) 
      _nLinha+=_nPula

    @ _nLinha+1, _nCol1 Say "Data Inicial" SIZE 060,010  OF _oDlg PIXEL 
    @ _nLinha  , _nCol2 MSGET _dDT_Ini  PICTURE "@D" SIZE _nTam,008 OF _oDlg PIXEL VALID NaoVazio(_dDT_Ini)
      _nLinha+=_nPula

    @ _nLinha+1, _nCol1 Say "Data Final" SIZE 060,010  OF _oDlg PIXEL 
    @ _nLinha  , _nCol2 MSGET _dDT_Fim  PICTURE "@D" SIZE _nTam,008 OF _oDlg PIXEL VALID NaoVazio(_dDT_Ini)
      _nLinha+=_nPula

    @ _nLinha+1, _nCol1 Say "Bloquear" SIZE 060,010  OF _oDlg PIXEL 
    @ _nLinha  , _nCol2 MSCOMBOBOX _cBloq ITEMS {"1=Sim","2=Não"} SIZE 050, 010 OF _oDlg PIXEL Valid {|| Pertence('12')} 
      _nLinha+=_nPula

   Activate MSDialog _oDlg Centered

   If _nOpcao = 1

      (cAliasWK)->TRBF_OK:=cMarca

      M->ZZI_VLRPRV:=(M->ZZI_VLRPRV - (cAliasWK)->ZZI_VLRPRV + _nValor )//ACERTA O NIVEL da capa
      ZZI->(RecLock("ZZI",.F.)) 
      ZZI->ZZI_VLRPRV:=M->ZZI_VLRPRV //EFETIVA A CAPA PQ O USUARIO PODE CANCELAR
      ZZI->(MSUnLock()) 

      _nSalvaValor:=(cAliasWK)->ZZI_VLRPRV

      (cAliasWK)->ZZI_VLRPRV:=_nValor 
      (cAliasWK)->ZZI_DTINIC:=_dDT_Ini
      (cAliasWK)->ZZI_DTFIM :=_dDT_Fim
      (cAliasWK)->ZZI_MSBLQL:=_cBloq
      
      ZZI->(DBGoTo((cAliasWK)->REC_ZZI))
      ZZI->(RecLock("ZZI",.F.)) 
      ZZI->ZZI_VLRPRV:=_nValor 
      ZZI->ZZI_DTINIC:=_dDT_Ini
      ZZI->ZZI_MSBLQL:=_cBloq
      ZZI->ZZI_DTFIM :=_dDT_Fim
      ZZI->(MSUnLock()) 

      If Left(M->ZZI_TIPO,1) = "1" .And. (cAliasWK)->ZZI_TIPO = "3" 
         (cAliasWK)->(DBSetOrder(2))
         If (cAliasWK)->(DBSeek( _cNivel2  ))//Vai no N2 do N3 para acertar o valor
            (cAliasWK)->ZZI_VLRPRV:=((cAliasWK)->ZZI_VLRPRV - _nSalvaValor + _nValor )//ACERTA NO NIVEL 2
            ZZI->(DBGoTo((cAliasWK)->REC_ZZI))
            ZZI->(RecLock("ZZI",.F.)) 
            ZZI->ZZI_VLRPRV:=(ZZI->ZZI_VLRPRV - _nSalvaValor + _nValor )//ACERTA NO NIVEL 2
            ZZI->(MSUnLock()) 
         EndIf
      EndIf
      (cAliasWK)->(DBGoTo(_nRecAtuWR))//POSICIONA DE VOLTA NO NIVEL DA LINHA NO TRB
      FWAlertSuccess("Dados gravados com sucesso.","ACOM00313")
   ElseIf _nOpcao = 2 
      ZZI->(DBGoTo((cAliasWK)->REC_ZZI))//Posiciona no ZZI da linha do TRB para validar se tá em alguma SC
      If !U_ACOM003E(.T.)
         Exit
      EndIf

      (cAliasWK)->TRBF_OK:=cMarca

      M->ZZI_VLRPRV:=(M->ZZI_VLRPRV - (cAliasWK)->ZZI_VLRPRV )//ACERTA O NIVEL da capa
      ZZI->(RecLock("ZZI",.F.)) 
      ZZI->ZZI_VLRPRV:=M->ZZI_VLRPRV //EFETIVA A CAPA PQ O USUARIO PODE CANCELAR
      ZZI->(MSUnLock()) 

      If Left(M->ZZI_TIPO,1) = "1" .And. (cAliasWK)->ZZI_TIPO = "3"
         (cAliasWK)->(DBSetOrder(2))
         If (cAliasWK)->(DBSeek( _cNivel2  ))//Vai no N2 do N3 para acertar o valor
            (cAliasWK)->ZZI_VLRPRV:=(ZZI->ZZI_VLRPRV - (cAliasWK)->ZZI_VLRPRV )//ACERTA O VALOR NO NIVEL 2 DO N3
            ZZI->(DBGoTo((cAliasWK)->REC_ZZI))
            ZZI->(RecLock("ZZI",.F.)) 
            ZZI->ZZI_VLRPRV:=(ZZI->ZZI_VLRPRV - (cAliasWK)->ZZI_VLRPRV )//ACERTA O VALOR NO NIVEL 2 DO N3
            ZZI->(MSUnLock()) 
         EndIf		
      ElseIf Left(M->ZZI_TIPO,1) = "1" .And. (cAliasWK)->ZZI_TIPO = "2" 
         (cAliasWK)->(DBSetOrder(2))
         While (cAliasWK)->(DBSeek( _cCodigo  )) .And. (cAliasWK)->(!Eof())//Vai nos N3 para deletar
            ZZI->(DBGoTo((cAliasWK)->REC_ZZI))
            ZZI->(RecLock("ZZI",.F.)) 
            ZZI->(DBDELETE()) 
            ZZI->(MSUnLock()) 
            (cAliasWK)->(DBDELETE()) 
         EndDo
      EndIf

      (cAliasWK)->(DBGoTo(_nRecAtuWR))//POSICIONA DE VOLTA NO NIVEL DA LINHA NO TRB
      ZZI->(DBGoTo((cAliasWK)->REC_ZZI))
      ZZI->(RecLock("ZZI",.F.)) 
      ZZI->(DBDELETE()) 
      ZZI->(MSUnLock()) 

      (cAliasWK)->(DBDELETE()) //DELETA LINHA ATUAL

      FWAlertSuccess("Dados excluídos com sucesso.","ACOM00314")
      
      (cAliasWK)->(DBSetOrder(1))
      (cAliasWK)->(DBGoTop())

   EndIf
   Exit
EndDo

ZZI->(DBSetOrder(1))
ZZI->(DBGoTo(_nRecAtual))//POSICIONA DE VOLTA NO NIVEL DO CADASTRO PARA ACERTO

oMark:oBrowse:Refresh()
oEnCh1:Refresh()
Return .T.

/*
===============================================================================================================================
Programa--------: ACOM03DT()
Autor-----------: Julio de Paula Paz
Data da Criacao-: 25/11/2022
Descrição-------: Na alteração da data principal de inicio e fim, replica os valores para as datas dos níveis inferiores.
Parametros------: _cCampo = Campo que chamou a rotina
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ACOM03DT(_cCampo)
Local _nRegAtu 

Begin Sequence 
   
   If _cCampo == "ZZI_DTINIC"
      _cRet := M->ZZI_DTINIC
   EndIf 

   If _cCampo == "ZZI_DTFIM"
      _cRet := M->ZZI_DTFIM
   EndIf 

   If ! ALTERA
      Break
   EndIf 

   If M->ZZI_TIPO <> "1"
      Break 
   EndIf 
   
   _nRegAtu := (cAliasWK)->(Recno())
   
   (cAliasWK)->(DBGoTop())
   While ! (cAliasWK)->(Eof())
      
      If (cAliasWK)->ZZI_DTINIC <> M->ZZI_DTINIC
         (cAliasWK)->ZZI_DTINIC := M->ZZI_DTINIC 
      EndIf 

      If (cAliasWK)->ZZI_DTFIM <> M->ZZI_DTFIM
         (cAliasWK)->ZZI_DTFIM := M->ZZI_DTFIM
      EndIf 
   
      (cAliasWK)->(DBSkip())
   EndDo 

   (cAliasWK)->(DBGoTo(_nRegAtu))
   
   oMark:oBrowse:Refresh()

End Sequence

Return _cRet
