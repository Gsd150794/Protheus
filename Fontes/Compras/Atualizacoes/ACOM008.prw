/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |30/05/2023| Chamado 43996. Validacao de acesso do usuario para colocar a data em branco.  
Lucas Borges  |22/04/2025| Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
Lucas Borges  |09/05/2025| Chamado 50617. Corrigir chamada estática no nome das tabelas do sistema
===============================================================================================================================
*/

#Include "TOTVS.ch"

#define	MB_OK				0
#define 	MB_ICONASTERISK	64

/*
===============================================================================================================================
Programa----------: ACOM008
Autor-------------: Darcio Ribeiro Sporl 
Data da Criacao---: 30/06/2015
Descrição---------: Rotina para alteração de data de faturamento por pedido de compras
Parametros--------: Nenhum
Retorno-----------: Nenhum 
===============================================================================================================================
*/
User Function ACOM008(_lAltLoja)

Local aArea			:= FWGetArea()
Local cGet1			:= SToD("//")
Local _cMotivo   	:= Space(Len(ZY1->ZY1_COMENT))
Local nX			:= 0
Local cQry			:= ""
Local cAliasQry		:= GetNextAlias()
Local aHeader		:= {}
Local aCols			:= {}
Local aRecnos		:= {}
Local aFields		:= {"C7_NUM","C7_TIPO","C7_ITEM","C7_I_DTFAT","C7_PRODUTO","C7_DESCRI","A2_NOME"}
Local aAlterFields	:= {}
Local nOpc			:= 0
Local _cCampoSX3

Local oGet1
Local oSayNDF
Local oSButton1
Local oSButton2
Local oDlg

Private oMSNewSC7

DBSelectArea("SY1")
SY1->(DBSetOrder(3)) //Y1_FILIAL + Y1_USER
If SY1->(DBSeek(xFilial("SY1") + __cUserId))
	
	If !_lAltLoja
		//Montagem do aheader
		aHeader := {}
		aCols   := {}
		For nX := 1 To Len(aFields)
			_cCampoSX3 := aFields[nX]
			aAdd( aHeader , {   Getsx3cache(_cCampoSX3,"X3_TITULO")  ,;
			Getsx3cache(_cCampoSX3,"X3_CAMPO")   ,;
			Getsx3cache(_cCampoSX3,"X3_PICTURE") ,;
			Getsx3cache(_cCampoSX3,"X3_TAMANHO") ,;
			Getsx3cache(_cCampoSX3,"X3_DECIMAL") ,;
			Getsx3cache(_cCampoSX3,"X3_VALID")   ,;
			Getsx3cache(_cCampoSX3,"X3_USADO")   ,;
			Getsx3cache(_cCampoSX3,"X3_TIPO")    ,;
			Getsx3cache(_cCampoSX3,"X3_F3")      ,;
			Getsx3cache(_cCampoSX3,"X3_CONTEXT")  })
		Next
	EndIf
	
	// Somente sao selecionados itens que nao possuem restricoes
	cQry := "SELECT C7_NUM,C7_TIPO,C7_ITEM,C7_PRODUTO,C7_DESCRI,C7_I_DTFAT,C7_FORNECE,C7_LOJA,SC7.R_E_C_N_O_ AS RECSC7,A2_NOME "
	cQry += "FROM " + RetSqlName("SC7") + " SC7 "
	cQry += "INNER JOIN " + RetSqlName("SA2") + " SA2 ON A2_FILIAL = '" + xFilial("SA2") + "' AND A2_COD = C7_FORNECE AND A2_LOJA = C7_LOJA AND SA2.D_E_L_E_T_ = ' ' "
	cQry += "WHERE C7_FILIAL = '" + xFilial("SC7") + "' "
	cQry += "  AND C7_NUM = '" + SC7->C7_NUM + "' "
	cQry += "  AND ((C7_QUJE < C7_QUANT "
	cQry += "  OR C7_QTDACLA > 0 ) "
	cQry += "  AND C7_RESIDUO <> 'S') "
	cQry += "  AND SC7.D_E_L_E_T_ = ' ' "
	cQry := ChangeQuery(cQry)
	MPSysOpenQuery(cQry,cAliasQry)
	
	(cAliasQry)->( DBGoTop() )
	
	If !(cAliasQry)->(Eof())
		
		If !_lAltLoja
		   
		   While (cAliasQry)->(!Eof())
				aAdd(aCols,		{(cAliasQry)->C7_NUM, (cAliasQry)->C7_TIPO, (cAliasQry)->C7_ITEM, SToD((cAliasQry)->C7_I_DTFAT), (cAliasQry)->C7_PRODUTO, (cAliasQry)->C7_DESCRI,  (cAliasQry)->A2_NOME,.F.})
				aAdd(aRecnos,	(cAliasQry)->RECSC7)
				(cAliasQry)->(DBSkip())
		   EndDo
			
			DEFINE MSDIALOG oDlg TITLE "Pedido de Compra - Alt.Dt.Fat.PC" FROM 000, 000  TO 300, 700 COLORS 0, 16777215 PIXEL
			
			oMSNewSC7 := MsNewGetDados():New( 001, 002, 101, 348, , "AllwaysTrue", "AllwaysTrue", "", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oDlg, aHeader, aCols)
			@ 109, 002 Say oSayNDF PROMPT "Nova Data Faturamento: " SIZE 060, 007 OF oDlg COLORS 0, 16777215 PIXEL
			@ 107, 064 MSGET oGet1 VAR cGet1 SIZE 055, 010 OF oDlg VALID U_VLDDTFAT(cGet1,2,aRecnos) COLORS 0, 16777215 PIXEL
			
			@ 109, 125 Say "Comentario:" SIZE 060, 007 OF oDlg COLORS 0, 16777215 PIXEL
			@ 107, 155 MSGET _cMotivo    SIZE 190, 010 OF oDlg COLORS 0, 16777215 PIXEL
			
			DEFINE SBUTTON oSButton1 FROM 129, 142 Type 01 OF oDlg ENABLE ACTION (If(VLDUSER(cGet1),(nOpc:=1, oDlg:End()),))
			DEFINE SBUTTON oSButton2 FROM 129, 175 Type 02 OF oDlg ENABLE ACTION (nOpc := 0, oDlg:End())
			
			ACTIVATE MSDIALOG oDlg CENTERED
			
		Else
			
		   While (cAliasQry)->(!Eof())
				aAdd(aRecnos,	(cAliasQry)->RECSC7)
				(cAliasQry)->(DBSkip())
		   EndDo
			cGetFor :=SC7->C7_FORNECE
			cGetLoj :=SC7->C7_LOJA
			cGetDFor:=Posicione("SA2",1,xFilial("SA2")+SC7->C7_FORNECE+SC7->C7_LOJA,"A2_NREDUZ")
  			cNovLoj :=Space(Len(SC7->C7_LOJA))
            aNovLoj :={}
			If SA2->(DBSeek(xFilial("SA2")+SC7->C7_FORNECE))
			   While SA2->(!Eof()) .And. xFilial("SA2")+SC7->C7_FORNECE == SA2->A2_FILIAL+SA2->A2_COD
			      If SA2->A2_MSBLQL <> '1'
			         If RetPessoa(SA2->A2_CGC) == "F"
			         	cCNPJCli := Transform(SA2->A2_CGC,"@R 999.999.999-99")
         			Else                                                      
		         		cCNPJCli := Transform(SA2->A2_CGC,"@R! NN.NNN.NNN/NNNN-99")
         			EndIf
			         aAdd(aNovLoj,SA2->A2_LOJA+" - "+cCNPJCli)
			      EndIf   
			      SA2->(DBSkip())
			   EndDo   
			EndIf

			DEFINE MSDIALOG oDlg TITLE "Pedido Compra - Alteração da Loja do Forncedor" FROM 000, 000  TO 190, 385 COLORS 0, 16777215 PIXEL
			
			@ 005, 006 Say "Fornecedor:" SIZE 030, 007 OF oDlg PIXEL
			@ 015, 006 MSGET cGetFor     SIZE 050, 010 OF oDlg READONLY PIXEL  F3 "SA2"
			
			@ 005, 070 Say "Nome:"       SIZE 025, 007 OF oDlg PIXEL
			@ 015, 070 MSGET cGetDFor    SIZE 120, 010 OF oDlg READONLY PIXEL
			
			@ 029, 006 Say "Loja Atual:" SIZE 025, 007 OF oDlg PIXEL
			@ 039, 006 MSGET cGetLoj     SIZE 050, 010 OF oDlg READONLY PIXEL
			
			@ 029, 070 Say "Nova Loja:"  SIZE 041, 007 OF oDlg COLORS 16711680, 16777215 PIXEL
//			@ 040, 070 MSGET cNovLoj     SIZE 060, 010 OF oDlg PIXEL
            @ 039, 070 ComboBox cNovLoj  Items aNovLoj Size 120,80 Pixel Of oDlg VALID NaoVazio(cNovLoj)

	        @ 060, 006 Say "Comentario:" SIZE 056, 007 OF oDlg COLORS 16711680, 16777215 PIXEL
	        @ 059, 040 MSGET _cMotivo    SIZE 150, 010 OF oDlg PIXEL 
			
			DEFINE SBUTTON oSButton1 FROM 075, 064 Type 01 OF oDlg ENABLE ACTION (nOpc := 2, oDlg:End())
			DEFINE SBUTTON oSButton2 FROM 075, 118 Type 02 OF oDlg ENABLE ACTION (nOpc := 0, oDlg:End())
			
			ACTIVATE MSDIALOG oDlg CENTERED			
			
		EndIf
		
		If nOpc == 1

			If U_VLDDTFAT(cGet1,2,aRecnos)

			    _dDataOld:=CTOD("")
				DBSelectArea("SC7")
				For nX := 1 To Len(aRecnos)
					DBGoTo(aRecnos[nX])
					_dDataOld:=SC7->C7_I_DTFAT
					SC7->(RecLock("SC7",.F.))
					SC7->C7_I_DTFAT := cGet1
					SC7->(MSUnLock())
				Next nX

                ACOM8Monitor(_dDataOld,_cMotivo)
	            //Atualiza tabela ZZH de indicaores de pagamentos para pedidos de compra
	            U_ACOM008ZZH(AllTrim(SC7->C7_FILIAL), AllTrim(SC7->C7_NUM))

            	U_ITMsg("Data de Faturamento alterada de " + DToC(_dDataOld) + " para " + DToC(cGet1) +" com sucesso.","Atenção",,2)
	
			EndIf

		ElseIf nOpc == 2
            
            cNovLoj:=LEFT(cNovLoj,Len(SC7->C7_LOJA))
			
			DBSelectArea("SC7")
			For nX := 1 To Len(aRecnos)
				DBGoTo(aRecnos[nX])
				SC7->(RecLock("SC7",.F.))
				SC7->C7_LOJA := cNovLoj
				SC7->(MSUnLock())
			Next 
                
            _cMotivo:="Loja alterada de " + cGetLoj + " para " + cNovLoj+" - "+AllTrim(_cMotivo)
                
            ACOM8Monitor("",_cMotivo)

            U_ITMsg("Loja do Fornecedor alterada de " + cGetLoj + " para " + cNovLoj +" com sucesso.","Atenção",,2)

		EndIf
		
	Else
	
        U_ITMsg("Esse pedido possui itens com restrições","Pedido Inválido","Favor selecionar um pedido de compras válido!",1)
	
	EndIf
	
	(cAliasQry)->( DBCloseArea() )

Else

    U_ITMsg("O usuário: " + UsrFullName(__cUserId) + " não possui acesso para utilizar esta rotina.","Usuário Inválido","Verifique o cadastro do usuário como comprador.",1)

EndIf

// Grava log da alteração de data de faturamento por pedido de compras 
U_ITLOGACS('ACOM008')

FWRestArea(aArea)

Return    

/*
===============================================================================================================================
Programa----------: ACOM008ZZH 
Autor-------------: Josué Danich 
Data da Criacao---: 22/07/2015
Descrição---------: Rotina que atualiza a ZZH para um determinado pedido.
Parametros--------: _cfilial -> Filial do pedido que será atualizado para a ZZH
                    _cpedido -> Número do pedido que será atualziado para a ZZH
Retorno-----------: Nenhum 
===============================================================================================================================
*/
User Function ACOM008ZZH(_cfilial, _cpedido)

Local _dDtVenc := CTOD('')
Local _nTOTAL := 0
Local _aCond := ""
Local _nprorp := 0     
Local _aDadVenc := {}
Local _nI := 1
Local aArea			:= FWGetArea()  
Local _lIgual := .T. 
Local _ccondi := 0

//carrega dados do sc7
DBSelectArea("SC7")
SC7->( DBSetOrder(1) )
If SC7-> ( DBSeek(_cfilial + _cpedido) )

  While AllTrim(SC7->C7_FILIAL)+AllTrim(SC7->C7_NUM) == AllTrim(_cfilial)+AllTrim(_cpedido) .And. SC7->(!Eof())
  
   
    //só continua se tiver data de faturamento marcada
    If SC7->C7_I_DTFAT > ctod('01/01/2001')  
    
      _nTOTAL := ( ( ( (SC7->C7_PRECO * SC7->C7_QUANT )+SC7->C7_VALIPI+SC7->C7_DESPESA) - SC7->C7_VLDESC ) / SC7->C7_QUANT ) * ( SC7->C7_QUANT - SC7->C7_QUJE )
      _aCond		:= Condicao( _nTOTAL , SC7->C7_COND , 0 , SC7->C7_I_DTFAT )
      _lIgual := .T.
   
      //Arruma datas, proporcionalidade e monta matriz de vencimentos
      For _nI := 1 To Len( _aCond )
			
         _dDtVenc := DataValida( _aCond[_nI][01] ) //só dias úteis
	
         _nprorp := Round( _aCond[_nI][2]/_nTOTAL , 2 )  //indica proporcionalidade da parcela
 	            
         //se é primeira passagem grava a primeira proporção para comparar com as seeguintes
         If _nI == 1
 	              
             _ccondi := _nprorp
 	              
         Else
 	            
             If _ccondi != _nprorp  //compara para ver se tem proporção diferente da primeira
 	              
                _ligual := .F.
 	                
             EndIf
 	              
         EndIf  
	
         aAdd( _aDadVenc , { _dDtVenc , Round( _aCond[_nI][2] , 2 ), _nprorp, SC7->C7_ITEM } )
          
      Next _nI
              
      //verifica se _nprorp é igual para todas as parcelas
      // se For deixa zerado para o BI calcular o valor com menor margemd e erro por arredondamento
      If _ligual
                
         For _nI := 1 To Len( _aDadVenc )
                
            _aDadVenc[_nI][3] := 0
                
         Next _nI
                
      EndIf

    EndIf
	
	SC7-> ( DBSkip() )
		
  EndDo                   
  
  //primeiro apaga todos os registros do pedido
  DBSelectArea("ZZH")
  ZZH->( DBSetOrder(1) )
   
  If ZZH->( DBSeek( AllTrim(_cfilial)+AllTrim(_cpedido) ) )
   
     While AllTrim(ZZH->ZZH_PEDIDO) == AllTrim(_cpedido)
     
       ZZH->(RecLock( "ZZH" , .F. ) )
       ZZH->( DBDelete () )
       ZZH->(MSUnLock())
       
       ZZH-> ( DBSkip () )
       
     EndDo
   
  EndIf
       
  //Então reinclui     

  For _nI := 1 To Len( _aDadVenc ) 
  
      ZZH->(RecLock( "ZZH" , .T. ) )
      ZZH->ZZH_FILIAL := _cfilial
      ZZH->ZZH_PEDIDO := _cpedido
      ZZH->ZZH_DATA   := _aDadVenc[_nI][1]
      ZZH->ZZH_PRORP  := _aDadVenc[_nI][3]  
      ZZH->ZZH_ITEMPC := _aDadVenc[_nI][4]
      ZZH->ZZH_VALOR  := _aDadVenc[_nI][2]
      ZZH->(MSUnLock())
  
  Next _nI
		
EndIf

// Grava log da atualização da ZZH para um determinado pedido.
U_ITLOGACS('ACOM008ZZH')

FWRestArea(aArea)

Return

/*
===============================================================================================================================
Programa----------: ACOM8Monitor()
Autor-------------: Alex Wallauer
Data da Criacao---: 20/09/2018
Descrição---------: Rotina que atualiza a ZY1 do monitor
Parametros--------: _dDataOld:= dt anterior
Retorno-----------: Nenhum 
===============================================================================================================================
*/
Static Function ACOM8Monitor(_dDataOld,_cMotivo)

Local aRecnos2 := {} , nX
Local _cQryZY1 := "SELECT R_E_C_N_O_ ZY1_REC , ZY1_SEQUEN "
_cQryZY1 += "FROM " + RetSqlName("ZY1") + " "
_cQryZY1 += "WHERE ZY1_FILIAL = '" + SC7->C7_FILIAL + "' "
_cQryZY1 += "  AND ZY1_NUMPC = '" + SC7->C7_NUM + "' "
_cQryZY1 += "  AND D_E_L_E_T_ = ' ' "
_cQryZY1 := ChangeQuery(_cQryZY1)
MPSysOpenQuery(_cQryZY1,"TRBZY1")
	
TRBZY1->(DBGoTop())
_cSeque:="0"
If !TRBZY1->(Eof()) .And. !Empty(TRBZY1->ZY1_SEQUEN)

   While TRBZY1->(!Eof())
      aAdd(aRecnos2, TRBZY1->ZY1_REC )
      If Val(TRBZY1->ZY1_SEQUEN) > Val(_cSeque)
         _cSeque := TRBZY1->ZY1_SEQUEN
      EndIf
     TRBZY1->(DBSkip())
   EndDo
    _cSeque := Soma1(_cSeque)

Else
   _cSeque := StrZero(1,Len(ZY1->ZY1_SEQUEN)) 
EndIf   

TRBZY1->(DBCloseArea())

ZY1->(RecLock("ZY1", .T.))
ZY1->ZY1_FILIAL	:= SC7->C7_FILIAL
ZY1->ZY1_NUMPC	:= SC7->C7_NUM
ZY1->ZY1_SEQUEN	:= _cSeque
ZY1->ZY1_DTMONI	:= Date()
ZY1->ZY1_HRMONI	:= Time()
If Empty(_cMotivo)
   ZY1->ZY1_COMENT:="Data de faturamento alterada de " + DToC(_dDataOld) + " para " + DToC(SC7->C7_I_DTFAT)
Else
   ZY1->ZY1_COMENT:=_cMotivo
EndIf
ZY1->ZY1_CODUSR	:= __cUserId
ZY1->ZY1_NOMUSR	:= UsrFullName(__cUserId)
ZY1->ZY1_DTNECE := SC7->C7_DATPRF
ZY1->ZY1_DTFAT  := SC7->C7_I_DTFAT
ZY1->(MSUnLock())

For nX := 1 To Len(aRecnos2)
   ZY1->(DBGoTo(aRecnos2[nX]))
   ZY1->(RecLock("ZY1", .F.))
   ZY1->ZY1_DTFAT:= SC7->C7_I_DTFAT 
   ZY1->(MSUnLock())
Next nX

Return 

/*
===============================================================================================================================
Programa----------: VLDUSER()
Autor-------------: Alex Wallauer
Data da Criacao---: 30/05/2023
Descrição---------: Validacao do acesso do usuario 
Parametros--------: cGet1
Retorno-----------: _lRet := .T. OU .F. 
===============================================================================================================================
*/
Static Function VLDUSER(cGet1)
Local _lRet:=.T.
If ZZL->(FIELDPOS("ZZL_AUDTFA")) <> 0 .And. Empty(cGet1)
   If !U_ITVACESS( 'ZZL' , 3 , 'ZZL_AUDTFA' , "S" )
      U_ITMsg("O campo data de faturamento não pode ficar em branco.","VALIDACAO DA DATA",;
	          "Para deixar em branco, favor entrar em contato com Supervisor da Area de Compras!",3)
      _lRet := .F.
   EndIf
EndIf
Return _lRet
