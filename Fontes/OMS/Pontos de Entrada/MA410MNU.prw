/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor       |   Data   |                              Motivo
Josué Danich | 08/04/19 | Chamado 28694. Inclusão de botão de PV em planejamento logistico.
Julio PAz    | 11/04/19 | Chamado 28585. Alteração Transfer.Pedidos em duas Opções:Ped.Posicionado e Varios Pedidos.  
Josué Danich | 29/05/19 | Chamado 29435. Ajuste de espelho de pedido do portal para localizar multifiliais.
Jerry        | 01/12/20 | Chamado 34860. Mostra Nota no Botão Pesquisar PV. 
Julio Paz    | 09/12/20 | Chamado 34761. Inclusão no menu, novo relatorio Espelho de Pedido Portal que roda sobre SC5/SC6.
Jerry        | 15/02/21 | Chamado 35371. Alteração na Chamado do Espelho do Pedido Portal e Protheus. 
Julio Paz    | 30/07/21 | Chamado 37313. Desenvolver rotina para visualização dos dados: operador logisticos e redespacho.
Igor Melgaço | 26/07/24 | Chamado 47487. Novas opções de busca no Localizar PV / Senha do PV e Pedido do Cliente.
=================================================================================================================================================================================================
Analista         - Programador     - Inicio     - Envio    - Chamado - Motivo da Alteração
=================================================================================================================================================================================================
Vanderlei Alves  - Alex Wallauer   - 06/06/25   - 10/06/25 - 45229   - Retirada do parâmetro p/determinar se a integração WebS. será TMS Multiembarcador ou RDC para chamar a U_IT_TMS(_cLocEmb).
=================================================================================================================================================================================================
*/

#Include "TOTVS.ch"
#Include "RwMake.ch"

/*
===============================================================================================================================
Programa----------: MA410MNU
Autor-------------: Wodson Reis Silva
Data da Criacao---: 16/07/2009
===============================================================================================================================
Descrição---------: Ponto de entrada na abertura do Browse de Pedidos de Venda para adição de itens ao menu principal.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: aRotina : array com as opções do menu
===============================================================================================================================
*/

User Function MA410MNU()

//============================================================
// Parametros do array a Rotina:                         
//                                                       
// 1. Nome a aparecer no cabecalho                       
// 2. Nome da Rotina associada                           
// 3. Reservado                                          
// 4. Tipo de Transacao a ser efetuada:                  
//      1 - Pesquisa e Posiciona em um Banco de Dados    
//      2 - Simplesmente Mostra os Campos                
//      3 - Inclui registros no Bancos de Dados          
//      4 - Altera o registro corrente                   
//      5 - Remove o registro corrente do Banco de Dados 
// 5. Nivel de acesso                                    
// 6. Habilita Menu Funcional                            
//============================================================

aAdd( aRotina , { 'Manutencao'				   , 'U_AOMS026'  , 0 , 2 , 0 , NIL } )          
aAdd( aRotina , { 'Transf.Pedido Posicionado', 'U_AOMS032("P")'	, 0 , 2 , 0 , NIL } )
aAdd( aRotina , { 'Transf.Varios Pedidos'	   ,  'U_AOMS032("V")'	, 0 , 2 , 0 , NIL } )
aAdd( aRotina , { 'Imprimir'				      , 'U_ROMS007'  , 0 , 2 , 0 , NIL } )
aAdd( aRotina , { 'Espelho Portal'	         , 'U_MA410ESP(1)'  , 0 , 2 , 0 , NIL } )
aAdd( aRotina , { 'Espelho Protheus  '	      , 'U_MA410ESP(2)'  , 0 , 2 , 0 , NIL } )
aAdd( aRotina , { 'WF Liberacao'			      , 'U_MOMS030()', 0 , 2 , 0 , NIL } )
aAdd( aRotina , { "Localiza PV"         	   , 'U_MA410LPV' , 0 , 1 , 0 , NIL } )
If cFilAnt = "91"
   aAdd( aRotina,{'Desconto P/C ZF'			   , 'U_MA410TRO()', 0 , 2 , 0 , NIL } )//Esta nesse fonta abaixo
EndIf

aAdd( aRotina,{'Solic.Ret.Pedido <== TMS', 'U_AOMS084B()', 0 , 2 , 0 , NIL } )
aAdd( aRotina,{'Devolve Pedido ==> TMS'  , 'U_AOMS084F()', 0 , 2 , 0 , NIL } )

aAdd( aRotina,{'Desmembra Pedido'	   , 'U_AOMS099()'	, 0 , 2 , 0 , NIL } )
aAdd( aRotina,{'Canhoto NF'	    	   , 'U_VISCANHO()', 0 , 2 , 0 , NIL } )//Esta no ITALACXFUN.PRW
aAdd( aRotina,{'Consulta Historico'    , 'U_COMS001()'	, 0 , 2 , 0 , NIL } )
aAdd( aRotina,{'Vincula Pedido' 	    	, 'U_AOMS110()'	, 0 , 2 , 0 , NIL } )
aAdd( aRotina,{'WF Desb Cliente'			, 'U_MOMS041Z()', 0 , 2 , 0 , NIL } )
aAdd( aRotina,{'Planej Logistico'		, 'U_MOMS042()', 0 , 2 , 0 , NIL } )


Return( aRotina )                                

/*
===============================================================================================================================
Programa----------: MA410Troca
Autor-------------: Alex Wallauer
Data da Criacao---: 09/08/2016
===============================================================================================================================
Descrição---------: Troca do conteudo do pararametro MV_DESZFPC
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MA410Troca() 

Local _lMV_DESZFPC	:=GetMv("MV_DESZFPC")
Local _cmens 		:= "Conteudo Atual: "+If(_lMV_DESZFPC,"Habilitado","Desabilitado")+CHR(13)+CHR(10)
Local _cmens2 		:= "Deseja " + If(_lMV_DESZFPC,"desabilitar","habilitar") +  " o desconto do PIS e COFINS para vendas? "
Local _lRet := U_ITMsg( _cmens + _cmens2 , "Desconto P/C Vendas Manaus (MV_DESZFPC)",,3,2 ,2 )

//grava log de acesso
u_itlogacs()

If _lRet .And. !_lMV_DESZFPC

   PutMV("MV_DESZFPC", .T. )
   U_ITMsg("Desconto P/C Vendas Manaus (MV_DESZFPC) habilitado com sucesso!","Atenção",,2)

ElseIf _lRet .And. _lMV_DESZFPC

   PutMV("MV_DESZFPC", .F. )
   U_ITMsg("Desconto P/C Vendas Manaus (MV_DESZFPC) desabilitado com sucesso!","Atenção",,2)

EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: MA410LPV()
Autor-------------: Alex Wallauer
Data da Criacao---: 16/09/2016
===============================================================================================================================
Descrição---------: Localiza Pedido de Venda 
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MA410LPV(cAlias,nReg,nOpc)

Local _cPV   := Space(50)
Local _cSay  := "Nr Pedido"
Local _lOK   := .F.
Local _oDlg, aCpoBrw:={},aSemSX3:={}
Local _nLinha:= 5
Local _nCol1 := 5//30
Local _nCol2 := _nCol1+65//073
Local _nTam  := 1100
Local _bValid:= {|| MA410Ler(_cPV,_cSay)  }
Local aCpoBusca := {"Nr Pedido","Pedido do Cliente","Senha do Pedido"}

Private aCampos:=ARRAY( SC5->(Fcount()) )
 
SX3->(DBSetOrder(2))

aAdd( aSemSX3 , { "C5_NOTA"   	, 'C' , 9 , 0 } )
aAdd( aSemSX3 , { "C5_SERIE"   	, 'C' , 3 , 0 } )
aAdd( aSemSX3 , { "C5_FILIAL"  	, 'C' , 2 , 0 } )
aAdd( aSemSX3 , { "C5_NUM"     	, 'C' , 6 , 0 } )
aAdd( aSemSX3 , { "C5_I_FLFNC" 	, 'C' , 2 , 0 } )
aAdd( aSemSX3 , { "C5_I_PDPR"  	, 'C' , 6 , 0 } )
aAdd( aSemSX3 , { "C5_I_FILFT" 	, 'C' , 2 , 0 } )
aAdd( aSemSX3 , { "C5_I_PDFT"  	, 'C' , 6 , 0 } )
aAdd( aSemSX3 , { "C5_CLIENTE" 	, 'C' , 6 , 0 } )
aAdd( aSemSX3 , { "C5_LOJACLI" 	, 'C' , 4 , 0 } )
aAdd( aSemSX3 , { "C5_I_NOME"  	, 'C' , 50 , 0 } )
aAdd( aSemSX3 , { "C5_VEND1"  	, 'C' , 50 , 0 } )
aAdd( aSemSX3 , { "C5_I_V1NOM" 	, 'C' , 6 , 0 } )
aAdd( aSemSX3 , { "C5_I_TRCNF" 	, 'C' , 1 , 0 } )
aAdd( aSemSX3 , { "C5_I_CARGA" 	, 'C' , 6 , 0 } )
aAdd( aSemSX3 , { "C5_I_PEDPA" 	, 'C' , 6 , 0 } )
aAdd( aSemSX3 , { "C5_I_PEDGE" 	, 'C' , 6 , 0 } )
aAdd( aSemSX3 , { "C5_I_NPALE" 	, 'C' , 6 , 0 } )
aAdd( aSemSX3 , { "WK_OPERAD" 	, 'C' , 12, 0 } )
aAdd( aSemSX3 , { "A2_COD" 	   , 'C' , 6 , 0 } )
aAdd( aSemSX3 , { "A2_LOJA" 	   , 'C' , 4 , 0 } )
aAdd( aSemSX3 , { "A2_NOME" 	   , 'C' , 40, 0 } )
aAdd( aSemSX3 , { "A2_NREDUZ"    , 'C' , 20, 0 } )
aAdd( aSemSX3 , { "A2_END" 	   , 'C' , 90, 0 } )
aAdd( aSemSX3 , { "A2_CEP" 	   , 'C' , 9 , 0 } )
aAdd( aSemSX3 , { "A2_MUN" 	   , 'C' , 50, 0 } )
aAdd( aSemSX3 , { "A2_EST" 	   , 'C' , 2 , 0 } )
aAdd( aSemSX3 , { "A2_DDD" 	   , 'C' , 3 , 0 } )
aAdd( aSemSX3 , { "A2_TEL" 	   , 'C' , 50, 0 } )
aAdd( aSemSX3 , { "A2_EMAIL" 	   , 'C' ,100, 0 } )
aAdd( aSemSX3 , { "TA2_COD" 	   , 'C' , 6 , 0 } )
aAdd( aSemSX3 , { "TA2_LOJA" 	   , 'C' , 4 , 0 } )
aAdd( aSemSX3 , { "TA2_NOME" 	   , 'C' , 40, 0 } )
aAdd( aSemSX3 , { "TA2_NREDUZ"   , 'C' , 20, 0 } )
aAdd( aSemSX3 , { "TA2_END" 	   , 'C' , 90, 0 } )
aAdd( aSemSX3 , { "TA2_CEP" 	   , 'C' , 9 , 0 } )
aAdd( aSemSX3 , { "TA2_MUN" 	   , 'C' , 50, 0 } )
aAdd( aSemSX3 , { "TA2_EST" 	   , 'C' , 2 , 0 } )
aAdd( aSemSX3 , { "TA2_DDD" 	   , 'C' , 3 , 0 } )
aAdd( aSemSX3 , { "TA2_TEL" 	   , 'C' , 50, 0 } )
aAdd( aSemSX3 , { "TA2_EMAIL" 	, 'C' ,100, 0 } )
aAdd( aSemSX3 , { "TA2_OK" 	, 'C' ,2, 0 } )


_otemp := FWTemporaryTable():New( "TRB", aSemSX3 )
_otemp:Create() 

aAdd(aCpoBrw,{"C5_FILIAL" ,,"Fil. Pedido"}) 
aAdd(aCpoBrw,{"C5_NUM" ,,"Nr Pedido"}) 
aAdd(aCpoBrw,{"C5_I_FLFNC",,"Fil. Carreg."})
aAdd(aCpoBrw,{"C5_I_PDPR" ,,"PV Carreg."})
aAdd(aCpoBrw,{"C5_I_FILFT",,"Fil. Fatur."})
aAdd(aCpoBrw,{"C5_I_PDFT" ,,"PV Fatur."})
aAdd(aCpoBrw,{"C5_NOTA",,"Nota"})
aAdd(aCpoBrw,{"C5_CLIENTE",,"Cod. Cli."})
aAdd(aCpoBrw,{"C5_LOJACLI",,"Loja"})
aAdd(aCpoBrw,{"C5_I_NOME" ,,"Cliente"})
aAdd(aCpoBrw,{"C5_VEND1"  ,,"Cod. Vend. 1"})
aAdd(aCpoBrw,{"C5_I_V1NOM",,"Vendedor"})
aAdd(aCpoBrw,{"C5_I_TRCNF",,"PV Troca NF?"})
aAdd(aCpoBrw,{"C5_I_CARGA",,"Carga"})
aAdd(aCpoBrw,{"C5_NOTA"   ,,"Nota"})
aAdd(aCpoBrw,{"C5_SERIE"  ,,"Serie"})
aAdd(aCpoBrw,{"C5_I_PEDPA",,"Ped. de Pallet?"})
aAdd(aCpoBrw,{"C5_I_PEDGE",,"Ped. Gerou Pallet?"})
aAdd(aCpoBrw,{"C5_I_NPALE",,"Pedido Pallet"})
aAdd(aCpoBrw,{ "WK_OPERAD",,"Tipo de Operador"})
aAdd(aCpoBrw,{ "A2_COD"   ,,"Código"})
aAdd(aCpoBrw,{ "A2_LOJA"  ,,"Loja"})
aAdd(aCpoBrw,{ "A2_NOME"  ,,"Razão Social"})
aAdd(aCpoBrw,{ "A2_NREDUZ",,"Nome Reduzido"})
aAdd(aCpoBrw,{ "A2_END"   ,,"Endereço"})
aAdd(aCpoBrw,{ "A2_CEP"   ,,"CEP"})
aAdd(aCpoBrw,{ "A2_MUN"   ,,"Cidade"})
aAdd(aCpoBrw,{ "A2_EST"   ,,"Estado"})
aAdd(aCpoBrw,{ "A2_DDD"   ,,"DDD"})
aAdd(aCpoBrw,{ "A2_TEL"   ,,"Telefone"})
aAdd(aCpoBrw,{ "A2_EMAIL" ,,"E-mail"})
aAdd(aCpoBrw,{ "TA2_COD"   ,,"Cód.Transportadora"})
aAdd(aCpoBrw,{ "TA2_LOJA"  ,,"Loja Transp."})
aAdd(aCpoBrw,{ "TA2_NOME"  ,,"Razão Social Transp."})
aAdd(aCpoBrw,{ "TA2_NREDUZ",,"Nome Reduzido Transp."})
aAdd(aCpoBrw,{ "TA2_END"   ,,"Endereço Transp."})
aAdd(aCpoBrw,{ "TA2_CEP"   ,,"CEP Transp."})
aAdd(aCpoBrw,{ "TA2_MUN"   ,,"Cidade Transp."})
aAdd(aCpoBrw,{ "TA2_EST"   ,,"Estado Transp."})
aAdd(aCpoBrw,{ "TA2_DDD"   ,,"DDD Transp."})
aAdd(aCpoBrw,{ "TA2_TEL"   ,,"Telefone Transp."})
aAdd(aCpoBrw,{ "TA2_EMAIL" ,,"E-mail Transp."})
aAdd(aCpoBrw,{ "TA2_OK" ,,"OK"})


While .T.
   oBusca := Nil
   _nLinha:=5
   _lOK   := .F.
   oMainWnd:ReadClientCoords()//So precisa declarar uma fez para o Programa todo
   DEFINE MSDIALOG _oDlg TITLE "Localiza Pedido de Venda (MA410MNU)" FROM 000,000 TO 200,_nTam OF oMainWnd PIXEL //650

      @ _nLinha+2, _nCol1     MSCOMBOBOX oBusca VAR _cSay ITEMS aCpoBusca   SIZE 60,10 OF _oDlg PIXEL ON CHANGE ( _cPV := Space(50) )  //F3 "SC5"
      @ _nLinha  , _nCol2     MSGET _cPV  SIZE 50,10 OF _oDlg VALID ( EVAL(_bValid) ) PIXEL //F3 "SC5  Picture "@!"
      @ _nLinha  , _nCol2+100 BUTTON "Visual. Ped." SIZE 50,11 ACTION U_MA410VPV(_oDlg) OF _oDlg PIXEL

      _nLinha+=17

      TRB->(DBGoTop())
    
      oMarkLPV:=MsSelect():New("TRB","TA2_OK",,aCpoBrw,.F.,"",{_nLinha,5,(_nLinha+75),  (_oDlg:nClientWidth-9)/2 })
      oMarkLPV:bMark := {|| U_MA410VPV(_oDlg)}
      oMarkLPV:oBrowse:bAllMark := { || }

   Activate MSDialog _oDlg Centered

   Exit

EndDo

_otemp:Delete()

Return .F.

/*
===============================================================================================================================
Programa----------: MA410Ler
Autor-------------: Alex Wallauer
Data da Criacao---: 16/09/2016
===============================================================================================================================
Descrição---------: Localiza Pedido de Venda 
===============================================================================================================================
Parametros--------: _cPV - numero do pedido de vendas
===============================================================================================================================
Retorno-----------: lógico indicando se achou pedido de vendas
===============================================================================================================================
*/
Static Function MA410Ler(_cPV,_cSay)

Local _cAliasSC5:= GetNextAlias(),lExistePV:=.F.
Local _lTemNF, _cCod, _cLoja, _cCodTransp, _cLojaTransp
Local _cTipoOperador
Local _cQuery  := ""

_cPV := AllTrim(_cPV)

If !Empty(_cPV)
   DBSelectArea("TRB")
   ZAP

   If Select(_cAliasSC5) > 0
      (_cAliasSC5)->( DBCloseArea() )
   EndIf

   _cQuery := " SELECT  SC5.R_E_C_N_O_ REC_SC5 "
   _cQuery += " FROM " + RetSqlName("SC5") + " SC5 "
   
   If _cSay == "Pedido do Cliente"
      _cQuery += " LEFT JOIN " + RetSqlName("SC6") + " SC6  ON C6_FILIAL = C5_FILIAL AND C6_NUM = C5_NUM AND SC6.D_E_L_E_T_ = ' ' "
   EndIf

   _cQuery += " WHERE SC5.D_E_L_E_T_ = ' ' "

   If _cSay == "Nr Pedido"
      _cQuery += "    AND SC5.C5_NUM     = '"+_cPV+"' "
   ElseIf _cSay == "Pedido do Cliente"
      _cQuery += "    AND SC6.C6_PEDCLI  = '"+_cPV+"' "
   ElseIf _cSay == "Senha do Pedido"
      _cQuery += "    AND SC5.C5_I_SENHA = '"+_cPV+"' "
   EndIf

   _cQuery += " GROUP BY SC5.R_E_C_N_O_ "

   DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAliasSC5 , .T. , .F. )

   SF2->(DBSetOrder(20)) // F2_FILIAL+F2_I_PEDID 
   SA2->(DBSetOrder(1))

   While (_cAliasSC5)->(!Eof())
      
      SC5->(DBGoTo( (_cAliasSC5)->REC_SC5 ))
      
      _cCodTransp  := ""
      _cLojaTransp := ""

      _lTemNF := .F.
      If SF2->(MsSeek(SC5->C5_FILIAL+SC5->C5_NUM))
         _cCodTransp  := SF2->F2_I_CTRA
         _cLojaTransp := SF2->F2_I_LTRA

         If !Empty(SF2->F2_I_REDP) 
            _cCod  := SF2->F2_I_REDP
            _cLoja := SF2->F2_I_RELO
            _lTemNF := .T.
            _cTipoOperador := "REDESPACHO"
         ElseIf !Empty(SF2->F2_I_OPER) 
            _cCod  := SF2->F2_I_OPER
            _cLoja := SF2->F2_I_OPLO
            _lTemNF := .T.
            _cTipoOperador := "LOGISTICO"
         EndIf   

         If _lTemNF
            SA2->(MsSeek(xFilial("SA2")+_cCod+_cLoja))
         EndIf
      EndIf 

      lExistePV:=.T.
      TRB->(DBAPPEND())
      AVREPLACE("SC5","TRB")
      If _lTemNF
         TRB->WK_OPERAD := _cTipoOperador
         TRB->A2_COD    := SA2->A2_COD
         TRB->A2_LOJA   := SA2->A2_LOJA
         TRB->A2_NOME   := SA2->A2_NOME
         TRB->A2_NREDUZ := SA2->A2_NREDUZ
         TRB->A2_END    := SA2->A2_END
         TRB->A2_CEP    := SA2->A2_CEP
         TRB->A2_MUN    := SA2->A2_MUN
         TRB->A2_EST    := SA2->A2_EST
         TRB->A2_DDD    := SA2->A2_DDD
         TRB->A2_TEL    := SA2->A2_TEL
         TRB->A2_EMAIL  := SA2->A2_EMAIL
      EndIf 

      If ! Empty(_cCodTransp) .And. SA2->(MsSeek(xFilial("SA2")+_cCodTransp+_cLojaTransp))
         TRB->TA2_COD    := SA2->A2_COD
         TRB->TA2_LOJA   := SA2->A2_LOJA
         TRB->TA2_NOME   := SA2->A2_NOME
         TRB->TA2_NREDUZ := SA2->A2_NREDUZ
         TRB->TA2_END    := SA2->A2_END
         TRB->TA2_CEP    := SA2->A2_CEP
         TRB->TA2_MUN    := SA2->A2_MUN
         TRB->TA2_EST    := SA2->A2_EST
         TRB->TA2_DDD    := SA2->A2_DDD
         TRB->TA2_TEL    := SA2->A2_TEL
         TRB->TA2_EMAIL  := SA2->A2_EMAIL      
      EndIf 

      (_cAliasSC5)->(DBSkip())
       
   EndDo

   TRB->(DBGoTop())
   oMarkLPV:oBrowse:Refresh()

   If !lExistePV
      U_ITMsg("A busca não encontrou dados!","Atenção",,1)
   EndIf
EndIf

Return .T.
 
/*
===============================================================================================================================
Programa----------: MA410ESP
Autor-------------: Josué Danich Prestes
Data da Criacao---: 26/03/2019
===============================================================================================================================
Descrição---------: Impressão de espelho do pedido do portal
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MA410ESP(_nOpcao)   

Local _cfilial       := cfilant
Private _aPed			:= {}
Private _nRadMnu1    := 1

Default _nOpcao      := 1

Begin Sequence
 
   If _nOpcao = 2
      U_ROMS064()
   Else   
      //Posiciona na SZW.
      SZW->(DBSetOrder(8))
      If SZW->(DBSeek(SC5->C5_I_IDPED))
         cfilant := SZW->ZW_FILIAL
         _aPed			:= {{AllTrim(SZW->ZW_FILIAL) ,AllTrim(SZW->ZW_IDPED) , AllTrim(SZW->ZW_CLIENTE) , AllTrim(SZW->ZW_LOJACLI) ,  SZW->ZW_VEND1 }}
         FWMsgRun(,{|oproc| U_ROMS035R(oproc)},"Aguarde...","Imprimindo espelho do pedido...")
         cfilant := _cfilial   
      Else
         U_ITMsg("Não foi localizado pedido do portal vinculado e este pedido de vendas","Atenção",,1)
      EndIf
   EndIf 

End Sequence

Return


/*
===============================================================================================================================
Programa----------: MA410VPV
Autor-------------: Igor Melgaço
Data da Criacao---: 26/07/2024
===============================================================================================================================
Descrição---------: Visualização do Pedido de Venda
===============================================================================================================================
Parametros--------: _cNum,_oDlg
===============================================================================================================================
Retorno-----------: .T.
===============================================================================================================================
*/
User Function MA410VPV(_oDlg) 
Local _cFilial := TRB->C5_FILIAL
Local _cNum := TRB->C5_NUM
Local _cFilBkp  := ""

DBSelectArea("SC5")
SC5->( DBSetOrder(1) )
If SC5->( DBSeek( _cFilial+_cNum ) )
   If _cFilial == cFilAnt
      _oDlg:End()
   Else
      _cFilBkp := cFilAnt
      cFilAnt := _cFilial
      MatA410(Nil, Nil, Nil, Nil, "A410Visual")
      cFilAnt := _cFilBkp
   EndIf
EndIf

Return .T.
