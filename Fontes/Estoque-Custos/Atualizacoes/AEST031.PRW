/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |09/05/2025| Chamado 50617. Corrigir chamada estática no nome das tabelas do sistema
Lucas Borges  |14/05/2025| Chamado 50697. Corrigir seleção do alias para evitar erro no gatilho
Alex Wallauer |06/05/2025| Chamado 50525. Ajuste para remoção de diretório Local C:\SMARTCLIENT\.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AEST031
Autor-------------: Erich Buttner
Data da Criacao---: 08/08/2013
Descrição---------: Cadastro de Eventos de tipo de custo gerencial - CHAMADO 3953  
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST031()

Private 	_cCadastro 	:= "Eventos de Custo Gerencial"
Private 	aRotina   	:= {}
Private 	aTitulos  	:= {}
Private 	aCores    	:= {}
Private 	aLegenda 	:= {} 
Private     _aRegrvCpos := {}
Private 	cRetF3   	:= ""//Retotno de todos os F3 do programa
Private     _cSeparador := "/"

aLegenda 	:= {{"BR_VERMELHO","Bloqueado"}, {"BR_VERDE", "Ativo"}} 

aAdd(aRotina,{"Pesquisar" 	,"AxPesqui"   		,0,1 })
aAdd(aRotina,{"Visualizar"	,"U_AEST031I(2)"    	,0,2 })
aAdd(aRotina,{"Incluir"		,"U_AEST031I(3)"		,0,3 })
aAdd(aRotina,{"Alterar"		,"U_AEST031I(4)"    	,0,4 })
aAdd(aRotina,{"Excluir"		,"U_AEST031I(5)"    	,0,5 })
aAdd(aRotina,{"Copiar"		,"U_AEST031I(6)"    	,0,6 })
aAdd(aRotina,{"Legenda"		,"BrwLegenda('Status das regras','Legenda',aLegenda)"  		,0,7 })

aAdd(aCores,{"ZL6_MSBLQL <> '1'","BR_VERDE" })   
aAdd(aCores,{"ZL6_MSBLQL = '1'" ,"BR_VERMELHO" })    

DBSelectArea("ZL6")
DBSetOrder(1)
aAdd(aTitulos,{"Filial      ","ZL6_FILIAL","C",2,0,"@!                                           "})
aAdd(aTitulos,{"Ordem"       ,"ZL6_ORDGRU" ,"C",6,0,"@!                                           "})
aAdd(aTitulos,{"Tipo Custo  ","ZL6_TPCUS","C",6,0,"@!                                           "})
aAdd(aTitulos,{"Descr Tp Cus","ZL6_DTPCUS","C",60,0,"@!                                           "})
aAdd(aTitulos,{"Grupo Custo ","ZL6_GRPCUS","C",6,0,"@!                                           "})
aAdd(aTitulos,{"Descr Grupo ","ZL6_DGRCUS","C",40,0,"@!                                           "})
aAdd(aTitulos,{"Cod. Evento ","ZL6_CODEVE","C",6,0,"@!                                           "})
aAdd(aTitulos,{"Descr Evento","ZL6_DESEVE","C",40,0,"@!                                           "})

ZL6->(DBGoTop())

mBrowse( 6, 1,22,75,"ZL6"  ,aTitulos,,,, ,aCores)

ZL6->(DBCloseArea())

Return(.T.)

/*
===============================================================================================================================
Programa----------: AEST031I
Autor-------------: Erich Buttner
Data da Criacao---: 08/08/2013
Descrição---------: Rotina de ações do mbrowse 
Parametros--------: _nOpc - 	2 - Visualizar
								3 - Incluir
								4 - Alterar
								5 - Excluir
								6 - Copiar
Retorno-----------: .T.
===============================================================================================================================
*/
User Function AEST031I(_nOpc)

Local _nI,_l
Local _cCadastro	:= "Eventos Tipo de Custo - "+If(_nOpc == 3,"Incluir",If(_nOpc == 4,"Alterar",If(_nOpc == 5, "Excluir",If(_nOpc == 2, "Visualizar",If(_nOpc == 6,"Copiar","")))))
Local _cLinok 		:= "U_AEST031L"
Local _cTudook 		:= "U_AEST031T"
Local _nOpce 		:= If(_nOpc == 5, 1,_nOpc)
Local _nOpcg 		:= If(_nOpc == 2 .Or. _nOpc == 5, 0 ,GD_INSERT + GD_UPDATE + GD_DELETE)
Local _lRetMod3 	:= .T.
Local _aButtons		:= {}
Local _aarea		:= FWGetArea()

//Log de utilização
U_ITLOGACS()

Private aCols 		:= {}
Private aHeader 	:= {}
Private aCpoEnc 	:= {}
Private aAltEnc 	:= {}
Private aAlt 		:= {}
Private cAlias1 	:= "ZL6"

Public nOpVld 		:= _nOpc

Regtomemory(cAlias1,(_nOpc=3))

If _nOpc <> 3

	 M->ZL6_FILIAL	:= ZL6->ZL6_FILIAL
	 M->ZL6_TPCUS	:= ZL6->ZL6_TPCUS
	 M->ZL6_DTPCUS	:= ZL6->ZL6_DTPCUS
	 M->ZL6_GRPCUS	:= ZL6->ZL6_GRPCUS
	 M->ZL6_DGRCUS	:= ZL6->ZL6_DGRCUS
	 If _nOpc == 6 // Copia
	 	  _ccod := U_AEST031G() //Caso seja copia valida ultimo cod. de numero do evento
	    M->ZL6_CODEVE	:= _ccod	
	 Else	
	    M->ZL6_CODEVE	:= ZL6->ZL6_CODEVE
	 EndIf	
	 M->ZL6_DESEVE:= ZL6->ZL6_DESEVE
   M->ZL6_ORDGRU:= ZL6->ZL6_ORDGRU
   If ZL6->(FIELDPOS("ZL6_PRDRAT")) <> 0
      M->ZL6_PRDRAT:= StrTran(M->ZL6_PRDRAT,_cSeparador,";")
   EndIf

EndIf

_aItalac_F3:={}
_bCond:={|| ZM0->ZM0_MSBLQL <> '1'}

aAdd(_aItalac_F3,{"M->ZL6_REGICE","ZM0",,,_bCond,"Regras ICMS ESTATUAL"} )
aAdd(_aItalac_F3,{"M->ZL6_REGICI","ZM0",,,_bCond,"Regras ICMS INTERESTATUAL"} )
aAdd(_aItalac_F3,{"M->ZL6_REGICT","ZM0",,,_bCond,"Regras ICMS TRANSFERENCIA"} )

_cSelectSB1:="SELECT B1_COD, B1_DESC FROM "+RETSQLNAME("SB1")+" SB1 WHERE B1_TIPO = 'PA' AND D_E_L_E_T_ = ' ' ORDER BY B1_COD " 
aAdd(_aItalac_F3,{"M->ZL6_PRDRAT",_cSelectSB1,{|Tab| AllTrim((Tab)->B1_COD) }, {|Tab| (Tab)->B1_DESC } , ,"Produtos Tipo: [PA]",,,,.F.        ,       , } )

AEST031CH(_nOpc)

AEST031CC(_nOpc)

nQtdLin := If(_nOpc == 2 , Len(aCols),999)

//====================================================================
//Abre tela de visulização do registro
//====================================================================

					  //   1     ,   2   , 3  ,  4    ,  5   ,   6   ,  7 ,   8 , 9 , 10, 11    ,  12   , 13, 14, 15, 16, 17,   18   ,  19  ,
_lRetMod3:= AEST031M3(_cCadastro,cAlias1,NIL, aCpoEnc,_cLinok,_cTudook,_nOpce,_nOpcg,NIL,.T.,nQtdLin,aAltEnc,NIL,NIL,NIL,NIL,NIL,@aHeader,@aCols,;
"+ZL6_SUBEVE",Nil,Nil,_aButtons,.F.,NIL	,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL	,250)
//   20     , 21, 22,   23    , 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39

DBSelectArea("ZL6")
If _lRetMod3 .And. (_nOpc == 3 ) // Inclusão
	
	For _l := 1 To Len(aCols)
	
		If !aCols[_l,Len(aHeader)+1]
	
			RecLock("ZL6",.T.)
            
			GrvCposCapa()
			
			For _nI := 1 to Len(aheader)
			    
			    If aScan(_aRegrvCpos,AllTrim(aheader[_nI][2]) ) = 0
				   ZL6->&(aheader[_nI][2]) := acols[_l][_nI]
				Else
				   ZL6->&(aheader[_nI][2]) := StrTran(acols[_l][_nI],_cSeparador,";")
				EndIf   
			
			Next
	
			ZL6->(MSUnLock())
			
		EndIf

	Next _l

	ConfirmSX8()
	
ElseIf _lRetMod3 .And. (_nOpc == 4 ) // Alteração
	
	For _l := 1 To Len(aCols)

		If !aCols[_l,Len(aHeader)+1]

			ZL6->(DBSetOrder(7))

			If ZL6->(DBSeek(M->ZL6_FILIAL+aCols [_l,aScan(aHeader,{ |x| AllTrim(x[2]) == 'ZL6_SUBEVE'} )]+M->ZL6_CODEVE+M->ZL6_TPCUS+M->ZL6_GRPCUS))

				RecLock("ZL6",.F.)

			Else

				RecLock("ZL6",.T.)

			EndIf
			
			GrvCposCapa()

			For _nI := 1 to Len(aheader)
			
			    If aScan(_aRegrvCpos,AllTrim(aheader[_nI][2]) ) = 0
				   ZL6->&(aheader[_nI][2]) := acols[_l][_nI]
				Else
				   ZL6->&(aheader[_nI][2]) := StrTran(acols[_l][_nI],_cSeparador,";")
				EndIf   
			
			Next
			
		Else
			ZL6->(DBSetOrder(7))

			If ZL6->(DBSeek(M->ZL6_FILIAL+aCols [_l,aScan(aHeader,{ |x| AllTrim(x[2]) == 'ZL6_SUBEVE'} )]+M->ZL6_CODEVE+M->ZL6_TPCUS+M->ZL6_GRPCUS))

				RecLock("ZL6",.F.)
				ZL6->(DbDelete())
				ZL6->(MSUnLock())

			EndIf

			aCols [_l,Len(aHeader)+1] := .T.

		EndIf

	Next _l



ElseIf _lRetMod3 .And. (_nOpc == 5 ) // Exclusão
	
	For _l := 1 To Len(aCols)
	
		DBSetOrder(7)

		If ZL6->(DBSeek(M->ZL6_FILIAL+aCols [_l,aScan(aHeader,{ |x| AllTrim(x[2]) == 'ZL6_SUBEVE'} )]+M->ZL6_CODEVE+M->ZL6_TPCUS+M->ZL6_GRPCUS))

			RecLock("ZL6",.F.)
			ZL6->(DbDelete())
			ZL6->(MSUnLock())

		EndIf

	Next _l

ElseIf _lRetMod3 .And. (_nOpc == 6 ) // Copia
	
	For _l := 1 To Len(aCols)

		If !aCols[_l,Len(aHeader)+1]

			ZL6->(DBSetOrder(7))

			RecLock("ZL6",.T.)

			GrvCposCapa()
			
			For _nI := 1 to Len(aheader)
			
			    If aScan(_aRegrvCpos,AllTrim(aheader[_nI][2]) ) = 0
				   ZL6->&(aheader[_nI][2]) := acols[_l][_nI]
				Else
				   ZL6->&(aheader[_nI][2]) := StrTran(acols[_l][_nI],_cSeparador,";")
				EndIf   
			
			Next
	
			ZL6->(MSUnLock())
			
		EndIf
	
	Next _l

	ConfirmSX8()			


Else

	If _nOpc == 3 .Or. _nOpc == 6

		RollBackSX8()

	EndIf

EndIf


If _lRetMod3 .And. (_nOpc = 3  .Or. _nOpc = 4) // Inclusão OU alteração

	ZL6->(DBSetOrder(6))
	ZL6->(DBSeek(ZL6->ZL6_FILIAL+ZL6->ZL6_TPCUS+ZL6->ZL6_GRPCUS))//+ZL6->ZL6_CODEVE)
	cTpCust := ZL6->ZL6_TPCUS+ZL6->ZL6_GRPCUS//+ZL6->ZL6_CODEVE
	cFlCom := ZL6->ZL6_FILIAL

	While !(ZL6->( Eof() )) .And. ZL6->ZL6_FILIAL == cFlCom .And. cTpCust==ZL6->ZL6_TPCUS+ZL6->ZL6_GRPCUS//+ZL6->ZL6_CODEVE
		
		RecLock("ZL6",.F.)
	    ZL6->ZL6_ORDGRU	:= M->ZL6_ORDGRU
        If ZL6->(FIELDPOS("ZL6_PRDRAT")) <> 0
           ZL6->ZL6_PRDRAT:= StrTran(M->ZL6_PRDRAT,_cSeparador,";")
        EndIf
		ZL6->(MSUnLock())
		ZL6->( DBSkip() )
		
	EndDo

EndIf

FWRestArea(_aarea)

Return .T.

/*
===============================================================================================================================
Programa----------: AEST031CH
Autor-------------: Erich Buttner
Data da Criacao---: 08/08/2013
Descrição---------: Monta cabeçalho da tela de visualização de registros
Parametros--------: _nOpc - 	2 - Visualizar
								3 - Incluir
								4 - Alterar
								5 - Excluir
Retorno-----------: .T.
===============================================================================================================================
*/
Static Function AEST031CH(_nOpc)

Local nUsado := 0
Local _aAuxZL6 := ZL6->(DBSTRUCT())
Local _aZL6:={}

aCpoEnc := StrTokArr("ZL6_TPCUS|ZL6_DTPCUS|ZL6_GRPCUS|ZL6_DGRCUS|ZL6_CODEVE|ZL6_DESEVE|ZL6_ORDGRU|ZL6_PRDRAT|NOUSER","|")//Campos da Capa
aAltEnc := StrTokArr("ZL6_TPCUS|ZL6_DTPCUS|ZL6_GRPCUS|ZL6_DGRCUS|ZL6_CODEVE|ZL6_DESEVE|ZL6_ORDGRU|ZL6_PRDRAT","|")//Campos editaveis

For nUsado := 1 to Len(_aAuxZL6)
   aAdd(_aZL6,{_aAuxZL6[nUsado][1], Getsx3cache(_aAuxZL6[nUsado][1],"X3_ORDEM")} )
Next

aSort(_aZL6,,,{|X,Y| X[2] < Y[2] })//ORDEM DE ORDEM


_aRegrvCpos:={}

For nUsado := 1 to Len(_aZL6)

    _cCampo:=_aZL6[nUsado][1]
    _cF3:=Getsx3cache(_cCampo,"X3_F3")
    _cUsado:=Getsx3cache(_cCampo,"X3_USADO")
    If !Empty(_cF3)
       _cF3:=AVKEY(_cF3,"XB_ALIAS")

       SXB->(DBSeek(_cF3+"2"))//FUNCAO

       If "U_" $ Upper(AllTrim(SXB->XB_CONTEM))//Se o campo tem um F3 de LISTA com ;
          aAdd(_aRegrvCpos,AllTrim(_cCampo))
       EndIf   

       SXB->(DBSeek(_cF3+"5"))//RETORNO
    EndIf   
    
    If X3USO(_cUsado) .And. aScan(aAltEnc,_cCampo) = 0//Tira os campos da Capa

             aAdd( aHeader , {   Getsx3cache(_cCampo,"X3_TITULO")      ,;
                                 Getsx3cache(_cCampo,"X3_CAMPO")       ,;
                                 Getsx3cache(_cCampo,"X3_PICTURE")     ,;
                                 Getsx3cache(_cCampo,"X3_TAMANHO")     ,;
                                 Getsx3cache(_cCampo,"X3_DECIMAL")     ,;
                                 Getsx3cache(_cCampo,"X3_VALID")       ,;
                                 Getsx3cache(_cCampo,"X3_USADO")       ,;
                                 Getsx3cache(_cCampo,"X3_TIPO")        ,;
                                 Getsx3cache(_cCampo,"X3_F3")		   ,;
                                 Getsx3cache(_cCampo,"X3_CONTEXT")     })

           If _cCampo ="ZL6_OBSERV"
              _cCampo:="ZL6_OBSDES"//Inseri o Campo Virtual de Descrição
              aAdd( aHeader ,{   Getsx3cache(_cCampo,"X3_TITULO")      ,;
                                 Getsx3cache(_cCampo,"X3_CAMPO")       ,;
                                 Getsx3cache(_cCampo,"X3_PICTURE")     ,;
                                 Getsx3cache(_cCampo,"X3_TAMANHO")     ,;
                                 Getsx3cache(_cCampo,"X3_DECIMAL")     ,;
                                 Getsx3cache(_cCampo,"X3_VALID")       ,;
                                 Getsx3cache(_cCampo,"X3_USADO")       ,;
                                 Getsx3cache(_cCampo,"X3_TIPO")        ,;
                                 Getsx3cache(_cCampo,"X3_F3")		   ,;
                                 Getsx3cache(_cCampo,"X3_CONTEXT")     })
           EndIf   
                                               
    EndIf

Next

/* 

******************** LINHAS DE CONSULTA  DE DADOS DE DICONARIO FAVOR NÃO RETIRAR ESSES COMENTARIOS ************

aAdd(aheader,{"Ordem?","ZL6_ORDEM ","9999",4,0," ","€€€€€€€€€€€€€€ ","N"," ","R"," "," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Tipo Exec","ZL6_QTD   ","@!",1,0," ","€€€€€€€€€€€€€€ ","C"," ","R","1=Positivo;2=Negativo                                                                                                           "," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Infomacao"   ,"ZL6_OBSERV","@!",01,0,"PERTENCE('123456789ABCDEF')","€€€€€€€€€€€€€€ ","C","LSTMT9","R",""," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Desc. Origem","ZL6_OBSDES","@!",30,0,""                           ,"€€€€€€€€€€€€€€ ","C",""      ,"V",""," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Custo Eximpo","ZL6_EXIMPO"," ",1,0," ","€€€€€€€€€€€€€€ ","C"," ","R","S=Sim;N=Nao",'"S"                                                                                                                             ',"U_AEST031E('123')                                           "," "," ",.F.,.F.})
aAdd(aheader,{"Sub Evento","ZL6_SUBEVE","@!                                           ",4,0,"!Vazio()                                                                                                                        ","€€€€€€€€€€€€€€ ","C"," ","R"," "," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Descr Sub Ev","ZL6_DSUBEV","@!                                           ",60,0,"!Vazio()                                                                                                                        ","€€€€€€€€€€€€€€ ","C"," ","R"," "," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Grupo Prod.","ZL6_GRPPRO","@!                                           ",254,0," ","€€€€€€€€€€€€€€ ","C","LSTSBM","R"," "," ","U_AEST031E('12358')                                         "," "," ",.F.,.F.})
aAdd(aheader,{"Nao Grupo Pr","ZL6_NGRPPR"," ",254,0," ","€€€€€€€€€€€€€€ ","C","LSTSBM","R"," "," ","U_AEST031E('12358')                                         "," "," ",.F.,.F.})
aAdd(aheader,{"Clientes","ZL6_CLIENT"," ",100,0," ","€€€€€€€€€€€€€€ ","C","SA1ADD","R"," "," ","U_AEST031E('124')                                           "," "," ",.F.,.F.})
aAdd(aheader,{"Nao Clientes","ZL6_NCLIEN"," ",100,0," ","€€€€€€€€€€€€€€ ","C","SA1ADN","R"," "," ","U_AEST031E('124')                                           "," "," ",.F.,.F.})
aAdd(aheader,{"Fornecedores","ZL6_FORNEC"," ",100,0," ","€€€€€€€€€€€€€€ ","C","SA2ADD","R"," "," ","U_AEST031E('1249')                                          "," "," ",.F.,.F.})
aAdd(aheader,{"Cod. Produto","ZL6_CODPRO","@!                                           ",180,0," ","€€€€€€€€€€€€€€ ","C","SB1ADD","R"," "," ","U_AEST031E('12358A')                                        "," "," ",.F.,.F.})
aAdd(aheader,{"Nao Cod Pro","ZL6_NCODPR"," ",180,0," ","€€€€€€€€€€€€€€ ","C","SB1ADN","R"," "," ","U_AEST031E('12358')                                         "," "," ",.F.,.F.})
aAdd(aheader,{"Nao Forneced","ZL6_NFORNE"," ",100,0," ","€€€€€€€€€€€€€€ ","C","SA2ADN","R"," "," ","U_AEST031E('1249')                                          "," "," ",.F.,.F.})
aAdd(aheader,{"Cod Natureza","ZL6_NATURE","@!                                           ",100,0," ","€€€€€€€€€€€€€€ ","C","LSTNAT","R"," "," ","U_AEST031E('124')                                           "," "," ",.F.,.F.})
aAdd(aheader,{"Nao Natureza","ZL6_NNATUR"," ",100,0," ","€€€€€€€€€€€€€€ ","C","LSTNAT","R"," "," ","U_AEST031E('124')                                           "," "," ",.F.,.F.})
aAdd(aheader,{"Tipo Produto","ZL6_TPROD "," ",100,0," ","€€€€€€€€€€€€€€ ","C","LSTTIP","R"," "," ","U_AEST031E('12358')                                         "," "," ",.F.,.F.})
aAdd(aheader,{"Nao Tp Prod","ZL6_NTPRO "," ",100,0," ","€€€€€€€€€€€€€€ ","C","LSTTIP","R"," "," ","U_AEST031E('12358')                                         "," "," ",.F.,.F.})
aAdd(aheader,{"CF","ZL6_CF    "," ",100,0," ","€€€€€€€€€€€€€€ ","C","SD3CF ","R"," "," ","U_AEST031E('3')                                             "," "," ",.F.,.F.})
aAdd(aheader,{"Nao CF","ZL6_NCF   "," ",100,0," ","€€€€€€€€€€€€€€ ","C","SD3CF ","R"," "," ","U_AEST031E('3')                                             "," "," ",.F.,.F.})
aAdd(aheader,{"TES","ZL6_TES   "," ",100,0," ","€€€€€€€€€€€€€€ ","C","SF4LS2","R"," "," ","U_AEST031E('12')                                            "," "," ",.F.,.F.})
aAdd(aheader,{"Nao TES","ZL6_NTES  "," ",100,0," ","€€€€€€€€€€€€€€ ","C","SF4LS2","R"," "," ","U_AEST031E('12')                                            "," "," ",.F.,.F.})
aAdd(aheader,{"Tipo Nota","ZL6_TNOTA "," ",100,0," ","€€€€€€€€€€€€€€ ","C","LSTTPN","R"," "," ","U_AEST031E('12')                                            "," "," ",.F.,.F.})
aAdd(aheader,{"Nao Tp Nota","ZL6_NTNOT "," ",100,0," ","€€€€€€€€€€€€€€ ","C","LSTTPN","R"," "," ","U_AEST031E('12')                                            "," "," ",.F.,.F.})
aAdd(aheader,{"Centro Custo","ZL6_CENTRO","@!                                           ",99,0," ","€€€€€€€€€€€€€€ ","C","LSTCT2","R"," "," ","U_AEST031E('1235A')                                         "," "," ",.F.,.F.})
aAdd(aheader,{"Nao Centro C","ZL6_NCENTR"," ",100,0," ","€€€€€€€€€€€€€€ ","C","LSTCT2","R"," "," ","U_AEST031E('1235')                                          "," "," ",.F.,.F.})
aAdd(aheader,{"Tp Movimento","ZL6_TPMOV ","@!                                           ",100,0," ","€€€€€€€€€€€€€€ ","C","SF5LST","R"," "," ","U_AEST031E('3')                                             "," "," ",.F.,.F.})
aAdd(aheader,{"Nao Tp Movim","ZL6_NTPMOV"," ",100,0," ","€€€€€€€€€€€€€€ ","C","SF5LST","R"," "," ","U_AEST031E('3')                                             "," "," ",.F.,.F.})
aAdd(aheader,{"CFOP","ZL6_CFOP  ","@!                                           ",100,0," ","€€€€€€€€€€€€€€ ","C","LSTCF2","R"," "," ","U_AEST031E('12')                                            "," "," ",.F.,.F.})
aAdd(aheader,{"Nao Cfop","ZL6_NCFOP "," ",100,0," ","€€€€€€€€€€€€€€ ","C","LSTCF2","R"," "          ,"","U_AEST031E('12')                                            "," "," ",.F.,.F.})
aAdd(aheader,{"Bloqueado?","ZL6_MSBLQL"," ",1,0," ","€€€€€€€€€€€€€€ ","C"," "     ,"R","1=Sim;2=Não","2",""," "," ",.F.,.F.})
aAdd(aheader,{"Multiplicado","ZL6_RCMUL ","@E 999.99999999",12,8," ","€€€€€€€€€€€€€€ ","N"," ","R"," "," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Condicao","ZL6_CONDIC","@!                                           ",254,0," ","€€€€€€€€€€€€€€ ","C"," ","R"," "," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Verbas SRC","ZL6_RCPD  "," ",100,0," ","€€€€€€€€€€€€€€ ","C","LSTSRV","R"," "," ","U_AEST031E('7')                                             "," "," ",.F.,.F.})
aAdd(aheader,{"Regras","ZL6_REGRA ","@!                                           ",1,0," ","€€€€€€€€€€€€€€ ","C"," ","R","1=NORMAL;2=RESUMIDO;3=TOTAL;4=SUPRIME;5=NAOSOMA                                                                                 "," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Pis Cofins?","ZL6_PISCOF"," ",1,0," ","€€€€€€€€€€€€€€ ","C"," ","R","S=Sim;N=Nao                                                                                                                     "," ","U_AEST031E('1')                                             "," "," ",.F.,.F.})
aAdd(aheader,{"Conta qtde?","ZL6_CONTA "," ",1,0," ","€€€€€€€€€€€€€€ ","C"," ","R","S=Sim;N=Nao                                                                                                                     "," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Filiais?","ZL6_FILIS "," ",100,0," ","€€€€€€€€€€€€€€ ","C","LSTFIL","R"," "," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Origem","ZL6_ORIGEM"," ",100,0," ","€€€€€€€€€€€€€€ ","C"," ","R"," "," ","U_AEST031E('3')                                             "," "," ",.F.,.F.})
aAdd(aheader,{"N Origem","ZL6_NORIGE"," ",100,0," ","€€€€€€€€€€€€€€ ","C"," ","R"," "," ","U_AEST031E('3')                                             "," "," ",.F.,.F.})
aAdd(aheader,{"Ag. Imposto?","ZL6_TXFIN "," ",1,0," ","€€€€€€€€€€€€€€ ","C"," ","R","S=Sim;N=Nao                                                                                                                     "," ","U_AEST031E('4')                                             "," "," ",.F.,.F.})
aAdd(aheader,{"Beneficiario","ZL6_E5BENE"," ",100,0," ","€€€€€€€€€€€€€€ ","C"," ","R"," "," ","U_AEST031E('4')                                             "," "," ",.F.,.F.})
aAdd(aheader,{"N Benefeciar","ZL6_NE5BEN"," ",100,0," ","€€€€€€€€€€€€€€ ","C"," ","R"," "," ","U_AEST031E('4')                                             "," "," ",.F.,.F.})
aAdd(aheader,{"Prefixo","ZL6_E5PREF"," ",100,0," ","€€€€€€€€€€€€€€ ","C","LSTE5P","R"," "," ","U_AEST031E('4')                                             "," "," ",.F.,.F.})
aAdd(aheader,{"N prefixo","ZL6_NE5PRE"," ",100,0," ","€€€€€€€€€€€€€€ ","C","LSTE5P","R"," "," ","U_AEST031E('4')                                             "," "," ",.F.,.F.})
aAdd(aheader,{"Armazem","ZL6_LOCAL "," ",100,0," ","€€€€€€€€€€€€€€ ","C","LSTNNR","R"," "," ","U_AEST031E('123')                                           "," "," ",.F.,.F.})
aAdd(aheader,{"N Armazem","ZL6_NLOCAL"," ",100,0," ","€€€€€€€€€€€€€€ ","C","LSTNNR","R"," "," ","U_AEST031E('123')                                           "," "," ",.F.,.F.})
aAdd(aheader,{"Frete?","ZL6_D2FRET"," ",1,0," ","€€€€€€€€€€€€€€ ","C"," ","R","S=Sim;N=Nao                                                                                                                     "," ","U_AEST031E('2A')                                            "," "," ",.F.,.F.})
aAdd(aheader,{"OBS marcado?","ZL6_D3OBS "," ",1,0," ","€€€€€€€€€€€€€€ ","C"," ","R","S=Sim;N=Nao                                                                                                                     "," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Estado","ZL6_ESTADO"," ",100,0," ","€€€€€€€€€€€€€€ ","C","LSTEST","R"," "," ","U_AEST031E('2')                                             "," "," ",.F.,.F.})
aAdd(aheader,{"N Estado","ZL6_NESTAD"," ",100,0," ","€€€€€€€€€€€€€€ ","C","LSTEST","R"," "," ","U_AEST031E('2')                                             "," "," ",.F.,.F.})
aAdd(aheader,{"Tipo","ZL6_E5TIPO"," ",100,0," ","€€€€€€€€€€€€€€ ","C"," ","R"," "," ","U_AEST031E('4')                                             "," "," ",.F.,.F.})
aAdd(aheader,{"N Tipo","ZL6_NE5TIP"," ",100,0," ","€€€€€€€€€€€€€€ ","C"," ","R"," "," ","U_AEST031E('4')                                             "," "," ",.F.,.F.})
aAdd(aheader,{"Seg unidade?","ZL6_TUNID "," ",1,0," ","€€€€€€€€€€€€€€ ","C"," ","R","S=Sim;N=Nao                                                                                                                     "," ","U_AEST031E('3')                                             "," "," ",.F.,.F.})
aAdd(aheader,{"Divisor","ZL6_RCDIV ","@E 9.9999                                    ",12,8," ","€€€€€€€€€€€€€€ ","N"," ","R"," "," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Tipo custo g","ZL6_TCUSTO"," ",1,0," ","€€€€€€€€€€€€€€ ","C"," ","R","1=CUSTO OPERACIONAL;2=EMBALAGEM;3=FRETE;4=INSUMO;5=OUTROS;6=PRODUTO ACABADO;7=LEITE-MP                                          "," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Cod. Prod PA","ZL6_CODPR2","@!                                           ",180,0," ","€€€€€€€€€€€€€€ ","C","SB1ADD","R"," "," ","U_AEST031E('A')                                             "," "," ",.F.,.F.})
aAdd(aheader,{"Cod Leite Fr","ZL6_CODPR3","@!                                           ",180,0," ","€€€€€€€€€€€€€€ ","C","SB1ADD","R"," "," ","U_AEST031E('A')                                             "," "," ",.F.,.F.})
aAdd(aheader,{"RPA?","ZL6_RPA   ","@                                            ",1,0," ","€€€€€€€€€€€€€€ ","C"," ","R","S=Sim;N=Nao                                                                                                                     "," ","U_AEST031E('4')                                             "," "," ",.F.,.F.})
aAdd(aheader,{"Prx Mes?","ZL6_PRXMES"," ",1,0," ","€€€€€€€€€€€€€€ ","C"," ","R","S=Sim;N=Nao                                                                                                                     "," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Vct ou Emiss","ZL6_VENCTO"," ",1,0,'Pertence("SND")',"€€€€€€€€€€€€€€ ","C"," ","R",'S=Sim;N=Nao;D=Digitacao'," ","U_AEST031E('14')"," "," ",.F.,.F.})
aAdd(aheader,{"Vlr Icms","ZL6_VICMS ","@E 999,999,999.99                            ",18,2," ","€€€€€€€€€€€€€€ ","N"," ","R"," "," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Cust Prod?","ZL6_CUSPR"," ",1,0," ","€€€€€€€€€€€€€€ ","C"," ","R","S=Sim;N=Nao;A=Produto Aberto"," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Usa MIX?","ZL6_MIX   "," ",1,0," ","€€€€€€€€€€€€€€ ","C"," ","R","S=Sim;N=Nao;F=Sem Frete;P=Custo Cheio;L=Custo s/ Frete"," ","U_AEST031E('3')"," "," ",.F.,.F.})
aAdd(aheader,{"Cod.Setor","ZL6_SETOR "," ",100,0," ","€€€€€€€€€€€€€€ ","C","LSTZL2","R"," "," ","U_AEST031E('K')                                             "," "," ",.F.,.F.})
aAdd(aheader,{"Cod. Evento","ZL6_EVENTO"," ",6,0," ","€€€€€€€€€€€€€€ ","C"," ","R"," "," ","U_AEST031E('K')                                             "," "," ",.F.,.F.})
aAdd(aheader,{"Cod Mix","ZL6_CODMIX"," ",6,0," ","€€€€€€€€€€€€€€ ","C","ZLE_01","R"," "," ","U_AEST031E('K')                                             "," "," ",.F.,.F.})
aAdd(aheader,{"Prd Terceiro","ZL6_TERCEI"," ",1,0," ","€€€€€€€€€€€€€€ ","C"," ","R","S=Sim;N=Nao                                                                                                                     "," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Mult. Tercei","ZL6_TCMUL ","@E 99.9999                                   ",7,4," ","€€€€€€€€€€€€€€ ","N"," ","R"," "," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Div Terceiro","ZL6_TCDIV ","@E 99.9999                                   ",7,4," ","€€€€€€€€€€€€€€ ","N"," ","R"," "," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Qtde Manual","ZL6_MQTDE ","@E 9,999,999,999.9999                        ",15,4," ","€€€€€€€€€€€€€€ ","N"," ","R"," "," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Obs Manual","ZL6_MOBSER","@!                                           ",200,0," ","€€€€€€€€€€€€€€ ","C"," ","R"," "," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Valor Manual","ZL6_MVALOR","@E 9,999,999,999.9999                        ",15,4," ","€€€€€€€€€€€€€€ ","N"," ","R"," "," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Estoque Inic","ZL6_ESTANT","!                                            ",1,0," ","€€€€€€€€€€€€€€ ","C"," ","R","1=Estoque Inicial;2=Fechamanto Anterior (ZE0)                                                                                   "," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Frete Percus","ZL6_FRETPE","!",1,0,"Pertence('1234')","€€€€€€€€€€€€€€ ","C"," ","R","1=Leite;2=Soro;3=Soro C;4=Creme de Leite"," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Vlr FUNDOPEM","ZL6_VLFUOP","@E 99,999,999.99999                          ",14,5," ","€€€€€€€€€€€€€€ ","N"," ","R"," "," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Dif Aliquota","ZL6_DIFALQ","@E 99,999,999.99999                          ",14,5," ","€€€€€€€€€€€€€€ ","N"," ","R"," "," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Abate Descon","ZL6_ABTDES"," ",1,0," ","€€€€€€€€€€€€€€ ","C"," ","R","S=Sim;N=Nao"," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Vlr ICMS Est","ZL6_VICMSE","@E 99,999,999.99999                          ",14,5," ","€€€€€€€€€€€€€€ ","N"," ","R"," "," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Vlr ICMS Int","ZL6_VICMSI","@E 99,999,999.99999                          ",14,5," ","€€€€€€€€€€€€€€ ","N"," ","R"," "," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Vlr ICMS Tra","ZL6_VICMST","@E 99,999,999.99999                          ",14,5," ","€€€€€€€€€€€€€€ ","N"," ","R"," "," "," "," "," ",.F.,.F.})
aAdd(aheader,{"Ordem Grupo","ZL6_ORDGRU"," ",1,0,"NaoVazio()","€€€€€€€€€€€€€€ ","C"," ","R",""," "," "," "," ",.F.,.F.})
*/
Return

/*
===============================================================================================================================
Programa----------: AEST031CC
Autor-------------: Erich Buttner
Data da Criacao---: 08/08/2013
Descrição---------: Monta acols da tela de visualização de registros
Parametros--------: _nOpc - 	2 - Visualizar
								3 - Incluir
								4 - Alterar
								5 - Excluir
Retorno-----------: .T.
===============================================================================================================================
*/
Static Function AEST031CC(_nOpc)

Local _nQtdcpo := 0
Local _nI		:= 0
Local _nCols 	:= 0

_nQtdcpo := Len(aHeader)
aCols:= {}
aAlt := {}

If _nOpc == 3 
	
	aAdd(aCols,array(_nQtdcpo+1))
	
	For _nI := 1 to _nQtdcpo
		
		aCols[1,_nI] := Criavar(aHeader[_nI,2])
		
	Next _nI
	
	aCols[1,_nQtdcpo+1] := .F.
	nPosSeq		:= aScan(aHeader,{ |x| AllTrim(x[2]) == 'ZL6_SUBEVE'} )
	aCols[1,nPosSeq] := '0001'

Else
	
	DBSelectArea("ZL6")
	DBSetOrder(6)
	DBSeek(ZL6->ZL6_FILIAL+ZL6->ZL6_TPCUS+ZL6->ZL6_GRPCUS+ZL6->ZL6_CODEVE)
	cTpCust := ZL6->ZL6_TPCUS+ZL6->ZL6_GRPCUS+ZL6->ZL6_CODEVE
	cFlCom := ZL6->ZL6_FILIAL

	While !(ZL6->( Eof() )) .And. ZL6->ZL6_FILIAL == cFlCom .And. cTpCust==ZL6->ZL6_TPCUS+ZL6->ZL6_GRPCUS+ZL6->ZL6_CODEVE
		
		aAdd(aCols,array(_nQtdcpo+1))
		_nCols++
		
		For _nI := 1 to _nQtdcpo
			
			If aHeader[_nI,10] <> "V"
				
				aCols[_nCols,_nI] := Fieldget(Fieldpos(aHeader[_nI,2]))
				
			Else
				
				aCols[_nCols,_nI] := Criavar(aHeader[_nI,2],.T.)
				
			EndIf
			
		Next _nI
		
		aCols[_nCols,_nQtdcpo+1] := .F.
		aAdd(aAlt,ZL6->( Recno() ))
		ZL6->( DBSkip() )
		
	EndDo
	
EndIf


Return

/*
===============================================================================================================================
Programa----------: AEST031M3
Autor-------------: Marinaldo de Jesus
Data da Criacao---: 17/11/2005
Descrição---------: Monta Enchoice e GetDados	 do modelo 3
Parametros--------: Ver descrição abaixo
Retorno-----------: _lRet ( .T. Confirma, .F. Abandona )
===============================================================================================================================
*/
Static Function AEST031M3(;
cTitulo			,;	//01 -> Titulo da Janela
cAliasEnchoice	,;	//02 -> Alias da Enchoice
uUndefinedPar		,;	//03 -> Nao Usado ( Para Compatibilizar com a Modelo3 Padrao equivalente a cAlias2 )
aFieldsEnchoice	,;	//04 -> Array com campos da Enchoice
uGdLinhaOk			,;	//05 -> Linha OK na GetDados ( Public Functi on or CodeBlock )
uGdTudoOk			,;	//06 -> Tudo Ok na GetDados  ( Public Functi on or CodeBlock )
_nOpcEnchoice		,;	//07 -> _nOpc da Enchoice
_nOpcGetDados		,;	//08 -> _nOpc da GetDados
_cFieldok			,;	//09 -> Validacao para todos os campos da GetDados
_lVirtual			,;	//10 -> Permite visualizar campos virtuais na enchoice
_nLinhas			,;	//11 -> Numero Maximo de linhas na getdados
aAlteraEnchoice	,;	//12 -> Array com campos da Enchoice Alteraveis
_nFreeze			,;	//13 -> Congelamento das colunas na GetDados
oEnch				,;	//14 -> Objeto Enchoiche ( MsMGet():New() )
oGetDad1			,;	//15 -> Objeto GetDados ( MsNewGetDados:New() )
aAlteraGetDado  	,;	//16 -> Array com campos da GetDados Alteraveis
uGdDelOk			,;	//17 -> Validar Delecao de Item na GetDados ( Public Functi on or CodeBlock )
aGdHeader	 		,;	//18 -> Array com os Campos da GetDados
aGdCols			,;	//19 -> Array com os Itens da GetDados
cGdAutFieldNum	,;	//20 -> Campo para Numeracao Automatica na GetDados ( Sample: "+ZF_SEQ" )
aEncValid			,;	//21 -> Array com campos que devem ser Validados na Enchoice
aEncNotValid		,;	//22 -> Array com campos que nao devem ser Validados na Enchoice
_aButtons			,;	//23 -> Array com os Botoes para a EnchoiceBar
lDlgPadSiga		,;	//24 -> Dialog Padrao Siga
oDlg				,;	//25 -> Objeto Dialog
aObjSize			,;  //26 -> Coordenadas Para os Objetos Enchoice e GetDados
_cTudook			,;	//27 -> String Com Funcao para o TudoOk da Enchoice
bTudoOk			,;	//28 -> Bloco para Validar Todas as Informacoes da GetDados e da Enchoice
bSet15				,;	//29 -> Bloco para Acao do Botao OK
bSet24				,;	//30 -> Bloco para Acao do Botao Cancel
bMsDialogInit		,;	//31 -> Bloco para a Inicializacao do Dialog
cAtela				,;	//32 ->	cAtela ( Enchoice )
lNoFolder			,;	//33 -> lNoFolder ( Enhcoice )
lColumn			,;	//34 -> Se os Dados ficarao em apenas uma coluna ( Enchoice )
lDisableF3			,;	//35 -> Desabilitar Consulta via Tecla F3 ( Enchoice )
nColMens			,;	//36 -> nColMens ( Enchoice )
cMensagem			,;	//37 -> cMensagem ( Enchoice )
uSuperDel			,;  //38 -> Funcao ou CodeBlock para executar SuperDel na GetDados
nSizeHeader	 	 ;	//39 -> Utilizado no Alinamento dos Objetos
)						

Local _aSvKeys			:= GetKeys()
Local _aAdvSize
Local _aInfoAdvSize
Local _aObjCoords
Local _lRet
Local _lActivate		:= !( ValType( "oDlg" ) == "O" )
Local _lObjSize		:= !( ValType( aObjSize ) == "A" )
Local _nOpca			:= 0
Local _nReg				:= ( cAliasEnchoice )->( Recno() )

Private Altera,Inclui

Altera		:= .T.
Inclui		:= .T.

DEFAULT _nOpcEnchoice:= 3
DEFAULT _nOpcGetDados:= 3
DEFAULT _lVirtual		:= .T.
DEFAULT _nLinhas		:= 9999
DEFAULT lDlgPadSiga	:= .F.

If _nOpcEnchoice = 4
   aAlteraEnchoice:={"ZL6_ORDGRU","ZL6_DESEVE","ZL6_PRDRAT"}
EndIf
If (;
	( _lObjSize );
	.or.;
	( _lActivate );
	)

	_aAdvSize		:= MsAdvSize( NIL , lDlgPadSiga )
	_aInfoAdvSize	:= { _aAdvSize[1] , _aAdvSize[2] , _aAdvSize[3] , _aAdvSize[4] , 0 , 0 }

EndIf

If ( _lActivate )

	DEFINE MSDIALOG oDlg TITLE cTitulo FROM _aAdvSize[7],0 TO _aAdvSize[6],_aAdvSize[5] OF GetWndDefault() PIXEL

EndIf

DEFAULT nSizeHeader	:= 200

If ( _lObjSize )

	_aObjCoords		:= Array( 2 )
	_aObjCoords[1]	:= { 000 , nSizeHeader	, .T. , .F. }
	_aObjCoords[2]	:= { 000 , 000 			, .T. , .T. }
	aObjSize		:= MsObjSize( _aInfoAdvSize , _aObjCoords )

EndIf

oEnch 		:= MsMGet():New(;
cAliasEnchoice	,;	//01 -> cAlias	-> Alias da Tabela
_nReg				,;	//02 -> _nReg		-> Registro ( Recno() )
_nOpcEnchoice		,;	//03 -> _nOpc		-> Opcao retornada pelo aRotina
NIL					,;	//04 -> aCra
NIL					,;	//05 -> cLetras
NIL					,;	//06 -> cTexto
aFieldsEnchoice	,;	//07 -> aAcho 	-> Array de Campos que aparecerao na Enchoice
aObjSize[1]		,;	//08 -> aPos		-> Array com as Coordenadas da Enchoice
aAlteraEnchoice	,;	//09 -> aCpos		-> Array de Campos Alteraveis
3					,;	//10 -> nModelo
nColMens			,;	//11 -> nColMens
cMensagem			,;	//12 -> cMensagem
_cTudook			,;	//13 -> cTudook	-> String Com Funcao para o TudoOk da Enchoice
oDlg				,;	//14 -> oWnd		-> Objeto Dialog para a Enchoice
lDisableF3			,;	//15 -> lF3		-> Desabilitar Consulta via Tecla F3
_lVirtual			,;	//16 -> lMemoria	-> Se os Dados são de Memoria ( DEFAULT ) ou Arquivo
lColumn			,;	//17 -> lColumn	-> Se os Dados ficarao em apenas uma coluna
cAtela				,;	//18 -> cAtela
lNoFolder			 ;	//19 -> lNoFolder
)

oGetDad1		:=	MsNewGetDados():New(;
aObjSize[2,1]			,;	//01 -> nTop		Linha Inicial
aObjSize[2,2]			,;	//02 -> nLelft	Coluna Inicial
aObjSize[2,3]			,;	//03 -> nBottom	Linha Final
aObjSize[2,4]			,;	//04 -> nRight   	Coluna Final
_nOpcGetDados			,;	//05 -> nStyle:	Controle do que podera ser realizado na GetDado
uGdLinhaOk			 	,;	//06 -> ulinhaOK:	Funcao ou CodeBlock para validar a edicao da linha
uGdTudoOk				,;	//07 -> uTudoOK: 	Funcao ou CodeBlock para validar todas os registros da GetDados
cGdAutFieldNum		,;	//08 -> cIniCpos:	Campo para Numeracao Automatica
aAlteraGetDado		,;	//09 -> aAlter: 	Array unidimensional com os campos Alteraveis
_nFreeze				,;	//10 -> _nFreeze:	Numero de Colunas para o Freeze
_nLinhas				,;	//11 -> nMax:		Numero Maximo de Registros na GetDados
_cFieldok				,;	//12 -> _cFieldok:
uSuperDel				,;	//13 -> usuperdel:	Funcao ou CodeBlock para executar SuperDel na GetDados
uGdDelOk				,;	//14 -> udelOK:		Funcao, Logico ou CodeBlock para Verificar se Determinada Linha da GetDados pode ser Deletada
oDlg					,;	//15 -> oWnd:			Objeto Dialog onde a GetDados sera Desenhada
@aGdHeader	 		 	,;	//16 -> aParHeader:	Array com as Informacoes de Cabecalho
@aGdCols				 ;	//17 -> aParCols:		Array com as Informacoes de Detalhes
)

DEFAULT bTudoOk			:= { || (_nOpcEnchoice = 1 .Or. (EnchoTudOk( @oEnch , @aEncValid , @aEncNotValid ) .And. oGetDad1:TudoOk())) }
DEFAULT bSet15			:= { || If( Eval( bTudoOk ) , ( _nOpca := 1 , aGdCols := aClone( oGetDad1:aCols ) , oDlg:End() , RestKeys( _aSvKeys , .T. ) ) , _nOpca := 0 ) }
DEFAULT bSet24			:= { || _nOpca := 0 , oDlg:End() , RestKeys( _aSvKeys , .T. ) }
DEFAULT bMsDialogInit	:= { || EnchoiceBar( oDlg , bSet15 , bSet24 , NIL , _aButtons ),AlignObject( oDlg , { oEnch:oBox , oGetDad1:oBrowse } , 1 , NIL , { nSizeHeader } ), oGetDad1:Refresh()}

If ( _lActivate )

	ACTIVATE MSDIALOG oDlg ON INIT Eval( bMsDialogInit ) CENTERED

EndIf

RestKeys( _aSvKeys , .T. )

_lRet := ( _nOpca == 1 )

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AEST031L
Autor-------------: Erich Buttner
Data da Criacao---: 22/04/2013 
Descrição---------: Validação das linhas do acols
Parametros--------: Ver descrição abaixo
Retorno-----------: _lRet ( .T. Valida, .F. Bloqueia )
===============================================================================================================================
*/
User Function AEST031L()

Local _lRet 		:= .T.
Local _nI			:= 0
Local _nPosSbEve	:= aScan(aHeader,{ |x| AllTrim(x[2]) == 'ZL6_SUBEVE'} )
Local _nPosDSbEv	:= aScan(aHeader,{ |x| AllTrim(x[2]) == 'ZL6_DSUBEV'} )
Local _nPosMValor   := aScan(aHeader,{ |x| AllTrim(x[2]) == 'ZL6_MVALOR'} )
Local _nPosMQtde	:= aScan(aHeader,{ |x| AllTrim(x[2]) == 'ZL6_MQTDE' } )
Local _nPosMObs 	:= aScan(aHeader,{ |x| AllTrim(x[2]) == 'ZL6_MOBSER'} )
Local _nPosOBSERV   := aScan(aHeader,{ |x| AllTrim(x[2]) == 'ZL6_OBSERV'} )
Local _nPosPRXMES   := aScan(aHeader,{ |x| AllTrim(x[2]) == 'ZL6_PRXMES'} )
Local _nPosPERIOD   := aScan(aHeader,{ |x| AllTrim(x[2]) == 'ZL6_PERIOD'} )

For _nI := 1 To Len(aCols)

	If !aCols[_nI,Len(aHeader)+1] 
	
	    _cLinha:="Linha para corrigir: "+AllTrim(Str(_nI))

		If Empty(aCols[_nI,_nPosSbEve])
			U_ITMsg("Preencher o codigo do Sub-Evento",'Atenção!',_cLinha,1)
			_lRet := .F.
		EndIf

		If  Empty(aCols[_nI,_nPosDSbEv])
			U_ITMsg("Preencher o codigo da Descrição do Sub-Evento",'Atenção!',_cLinha,1)
			_lRet := .F.
		EndIf

		If aCols[_nI,_nPosOBSERV] = "B" .And. (Empty(aCols[_nI,_nPosMValor]) .Or. Empty(aCols[_nI,_nPosMQtde]) .Or. Empty(aCols[_nI,_nPosMObs]))
			U_ITMsg('Os campos "Valor Manual",  "Qtde Manual" e  "Obs Manual" devem ser preencidos quando o campo Informação For igual a Manual','Atenção!',_cLinha,1)
			_lRet := .F.
		EndIf

		If _nPosPERIOD = 0 
		   Return _lRet
		EndIf

		If aCols[_nI,_nPosPRXMES] = "P" .And. Empty(aCols[_nI,_nPosPERIOD]) 
			U_ITMsg('O campo "Periodo Dia" deve ser preenchido quando o campo Prx Mes For igual a "P" ','Atenção!',_cLinha,1)
			_lRet := .F.
		ElseIf aCols[_nI,_nPosPRXMES] = "P" .And. !Empty(aCols[_nI,_nPosPERIOD]) 
		
		    If Val(LEFT (aCols[_nI,_nPosPERIOD],2)) > 30 .Or. Val(LEFT (aCols[_nI,_nPosPERIOD],2)) < 1 .OR.;
		       Val(RIGHT(aCols[_nI,_nPosPERIOD],2)) > 30 .Or. Val(RIGHT(aCols[_nI,_nPosPERIOD],2)) < 1

			   U_ITMsg('O campo "Periodo Dia" esta com valores invalidos','Atenção!',"Valor validos somente de 1 a 30. "+_cLinha,1)
			   _lRet := .F.

			 EndIf  
		EndIf

	EndIf
	
Next _nI

Return _lRet

/*
===============================================================================================================================
Programa----------: AEST031T
Autor-------------: Erich Buttner
Data da Criacao---: 22/04/2013 
Descrição---------: Validação das da gravação do registro (tudook)
Parametros--------: Ver descrição abaixo
Retorno-----------: _lRet ( .T. Valida, .F. Bloqueia )
===============================================================================================================================
*/
User Function AEST031T()

Local _lRet := .T.

If nOpVld == 3

	DBSelectArea("ZL6")
	ZL6->( DBSetOrder(6) )
	
	If zl6->( DBSeek(xFilial("ZL6")+M->ZL6_TPCUS+M->ZL6_GRPCUS+M->ZL6_CODEVE) )
		U_ITMsg("Evento de custo gerencial já cadastrado!!",'Atenção!',,1)
		_lRet := .F.
	EndIf

EndIf

M->ZL6_ORDGRU:=StrZero(Val(M->ZL6_ORDGRU),Len(ZL6->ZL6_ORDGRU))

If _lRet
   _lRet:=U_AEST031L()
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: AEST031G
Autor-------------: Josué Danich
Data da Criacao---: 12/11/2015
Descrição---------: Rotina para retornar próximo código de evento para campo ZL6->CODEVE
Parametros--------: Ver descrição abaixo
Retorno-----------: _ccod - próximo valor para ZL6->CODEVE
===============================================================================================================================
*/
User Function AEST031G()

Local _ccod 	:= "000001"
Local _cQuery := ""
Local _aarea	:= FWGetArea()

_cQuery	:= " SELECT " 
_cQuery  	+= 	" MAX(ZL6_CODEVE) AS CODI" 
_cQuery  	+= 	" FROM " + RetSqlName("ZL6") + " ZL6 "
_cQuery  	+= 	" WHERE ZL6_FILIAL = '" + xFilial("ZL6") + "'"
_cQuery  	+= 	" AND (ZL6_TPCUS  = '" + AllTrim(M->ZL6_TPCUS) + "' OR ZL6_TPCUS  = '" + AllTrim(ZL6->ZL6_TPCUS) + "')
_cQuery  	+= 	" AND (ZL6_GRPCUS  = '" + AllTrim(M->ZL6_GRPCUS) + "' OR ZL6_GRPCUS  = '" + AllTrim(ZL6->ZL6_GRPCUS) +"')
_cQuery 	+= 	" AND ZL6.D_E_L_E_T_ = ' '	"
_cQuery := ChangeQuery(_cQuery)
MPSysOpenQuery(_cQuery,"ZL6T")

If !ZL6T->( Eof() )
	_ccod := StrZero( ( Val( ZL6T->CODI) + 1 ),6 )
EndIf

If Select("ZL6T") > 0 
	ZL6T->( DBCloseArea() )
EndIf

FWRestArea(_aarea)

Return _ccod

/*
===============================================================================================================================
Programa----------: AEST031E
Autor-------------: Josué Danich
Data da Criacao---: 16/12/2015
Descrição---------: Rotina para retornar estado de edição dos campos da ZL6
Parametros--------: _cnome - nome do campo
Retorno-----------: lógico - .T. editável, .F. só visualização
===============================================================================================================================
*/
User Function AEST031E(_cnome)

Local _lRet 		:= .T.

//Nova rotina
If _lRet .And. Len(_cnome) > 0 .And. AllTrim(acols[n][aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "ZL6_OBSERV" })]) $ _cnome
	Return _lRet
EndIf

//Campos do Mix
If _lRet .And. _cnome == "K" .And.  AllTrim(acols[n][aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "ZL6_MIX" })]) != "N"
	_lRet := .F.
EndIf

//Se está vazio o campo de informação não deixa mexer em nenhum dos outros
If Empty(AllTrim(acols[n][aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "ZL6_OBSERV" })]))
	_lRet := .F.
EndIf

//Campos para origem 1 - Notas de entrada
If _lRet .And. AllTrim(acols[n][aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "ZL6_OBSERV" })]) == '1'
	_lRet := .F.
EndIf

//Campos para origem 2 - Notas de saida
If _lRet .And. AllTrim(acols[n][aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "ZL6_OBSERV" })]) == '2'
	_lRet := .F.
EndIf

//Campos para origem 3 - Movimentos internos
If _lRet .And. AllTrim(acols[n][aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "ZL6_OBSERV" })]) == '3' .And. _cnome != "K"
	_lRet := .F.
EndIf

//Campos para origem 4 - Financeiro
If _lRet .And. AllTrim(acols[n][aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "ZL6_OBSERV" })]) == '4' .And. _cnome != "K"
	_lRet := .F.
EndIf

//Campos para origem 5 - Perdas de produção
If _lRet .And. AllTrim(acols[n][aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "ZL6_OBSERV" })]) == '5' .And. _cnome != "K"
	_lRet := .F.
EndIf

//Campos para origem 6 - MO
If _lRet .And. AllTrim(acols[n][aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "ZL6_OBSERV" })]) == '6' .And. _cnome != "K"
	_lRet := .F.
EndIf

//Campos para origem 7 - Horas extras
If _lRet .And. AllTrim(acols[n][aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "ZL6_OBSERV" })]) == '7' .And. _cnome != "K"
	_lRet := .F.
EndIf

//Campos para origem 8 - Saldos iniciais de estoque
If _lRet .And. AllTrim(acols[n][aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "ZL6_OBSERV" })]) == '8' .And. _cnome != "K"
	_lRet := .F.
EndIf

//Campos para origem 9 - Gestão do leite
If _lRet .And. AllTrim(acols[n][aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "ZL6_OBSERV" })]) == '9' .And. _cnome != "K"
	_lRet := .F.
EndIf

//Campos para origem A - Gestão do leite 
If _lRet .And. AllTrim(acols[n][aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "ZL6_OBSERV" })]) == 'A' .And. _cnome != "K"
	_lRet := .F.                                                                                   
EndIf		

Return _lRet 

/*
===============================================================================================================================
Programa----------: AEST031D
Autor-------------: Josué Danich Prestes	
Data da Criacao---: 17/12/2015
Descrição---------: Lista as Filiais do Sistema para seleção com exceção da filial atual
Parametros--------: lVldAcs	- Define se deve verificar o acesso do usuário às Filiais
Retorno-----------: .T.		- Compatibilização para utilização com F3
===============================================================================================================================
*/
User Function AEST031D( lVldAcs )

Local _aAcesso		:= FWEmpLoad(.F.),nI
Local _nI			:= 0
Local _nPadR		:= 0

Private nTam		:= 02
Private aCat		:= {}
Private MvRet		:= AllTrim( ReadVar() )
Private MvPar		:= ""
Private cTitulo		:= "Filiais do Sistema"
Private MvParDef	:= ""

Default lVldAcs		:= .F.

#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

//===========================================================================
//| Recupera dados das filiais                                              |
//===========================================================================
SM0->( DBSetOrder(1) )
SM0->( DBGoTop() )
While SM0->( !Eof() )
	
	If lVldAcs
		
		For nI := 1 To Len(_aAcesso)
			
			If AllTrim(SM0->M0_CODIGO) == AllTrim(_aAcesso[nI][01]) .And. AllTrim(SM0->M0_CODFIL) == AllTrim(_aAcesso[nI][03])
				
				If !(AllTrim(SM0->M0_CODFIL) == AllTrim(cfilant))
				
					MvParDef += AllTrim(SM0->M0_CODFIL)
					aAdd( aCat , AllTrim( SM0->M0_FILIAL ) )
				
				EndIf
				
				Exit
				
			EndIf
			
		Next nI
		
	Else
	
		If !(AllTrim(SM0->M0_CODFIL) == AllTrim(cfilant))
		
			MvParDef += AllTrim(SM0->M0_CODFIL)
			aAdd( aCat , AllTrim( SM0->M0_FILIAL ) )
			
		EndIf
	
	EndIf
	
SM0->( DBSkip() )
EndDo

nMaxSelect	:= Len(aCat)

If Empty(MvRet)
	MvRet := '_cGetFil'
EndIf

_nPadR := Len( &MvRet )

If Type("_cSeparador") <> "C"
   _cSeparador:=";"
EndIf 

//===========================================================================
//| Mantém a marcação anterior                                              |
//===========================================================================
If Len( AllTrim(&MvRet) ) == 0

	MvPar	:= PadR( AllTrim( StrTran( &MvRet , _cSeparador , "" ) ) , Len(aCat) )
	&MvRet	:= PadR( AllTrim( StrTran( &MvRet , _cSeparador , "" ) ) , Len(aCat) )

Else

	MvPar	:= AllTrim( StrTran( &MvRet , _cSeparador , "" ) )

EndIf

If Type("_cSeparador") <> "C"
   _cSeparador:=";"
EndIf 
//====================================================================================================
// Executa funcao que monta tela de opcoes
//====================================================================================================
If F_Opcoes( @MvPar , cTitulo , aCat , MvParDef , 12 , 49 , .F. , nTam , nMaxSelect )
	
	&MvRet := ''
	
	For _nI := 1 To Len( MvPar ) Step nTam
	
		If !( SubStr( MvPar , _nI , 1 ) $ " |*" )
			&MvRet += SubStr( MvPar , _nI , nTam ) + _cSeparador
		EndIf
		
	Next _nI
	
	&MvRet := PadR( SubStr( &MvRet , 1 , Len( &MvRet ) - 1 ) , _nPadR )

EndIf

cRetF3:=MvRet

Return(.T.)

/*
===============================================================================================================================
Programa----------: AEST031U
Autor-------------: Josué Danich
Data da Criacao---: 12/11/2015
Descrição---------: Define se campo M->ZL6_DESEVE será editável
Parametros--------: Nenhum
Retorno-----------: Lógico - Se é editável ou não
===============================================================================================================================
*/
User Function AEST031U()

Local _cQuery := ""
Local _aarea	:= FWGetArea()
Local _lRet	:= .F.

_cQuery	:= " SELECT " 
_cQuery  	+= 	" MAX(ZL6_CODEVE) AS CODI" 
_cQuery  	+= 	" FROM " + RetSqlName("ZL6") + " ZL6 "
_cQuery  	+= 	" WHERE ZL6_FILIAL = '" + xFilial("ZL6") + "'"
_cQuery  	+= 	" AND   ZL6_TPCUS  = '" + AllTrim(M->ZL6_TPCUS) + "'"
_cQuery  	+= 	" AND   ZL6_GRPCUS  = '" + AllTrim(M->ZL6_GRPCUS) + "'"
_cQuery 	+= 	" AND   ZL6.D_E_L_E_T_ 	= ' '	"

_cQuery := ChangeQuery(_cQuery)
MPSysOpenQuery(_cQuery,"ZL6T")

If ( Val( ZL6T->CODI) ) < ( Val ( M->ZL6_CODEVE) )
	_lRet := .T.
EndIf

If Select("ZL6T") > 0 
	ZL6T->( DBCloseArea() )
EndIf

FWRestArea(_aarea)

Return _lRet

/*
===============================================================================================================================
Programa----------: AEST031Y
Autor-------------: Josue Danich
Data da Criacao---: 29/10/2015
Descricao---------: Consulta múltipla para o cadastro de grupo de produtos
Parametros--------: Nenhum
Retorno-----------: .T.
===============================================================================================================================
*/
User Function AEST031Y()

Local i := 0
Local _aarea	:= FWGetArea()

Private nTam      := 0
Private aCat      := {}
Private MvRet     := AllTrim(ReadVar())
Private MvPar     := ""
Private cTitulo   := ""
Private MvParDef  := ""

#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

//Tratamento para carregar variaveis da lista de opcoes
nTam:=4
nMaxSelect := 14 //75 / 3
cTitulo :="Grupos de produtos"


cGrpCus:=" SELECT BM_GRUPO, BM_DESC FROM " + RETSQLNAME("SBM")
cGrpCus+=" WHERE D_E_L_E_T_ = ' ' "
cGrpCus+=" AND BM_FILIAL = '"+xFilial("SBM")+"' "
cGrpCus+=" AND BM_GRUPO >= '0'"
cGrpCus+=" ORDER BY BM_GRUPO"

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf

cGrpCus := ChangeQuery(cGrpCus)
MPSysOpenQuery(cGrpCus,"TRB")

While TRB->(!Eof())
	MvParDef += AllTrim(TRB->BM_GRUPO)
	aAdd(aCat,AllTrim(TRB->BM_DESC))
	TRB->(DBSkip())
EndDo

If Type("_cSeparador") <> "C"
   _cSeparador:=";"
EndIf 
/*
//==========================================================================
//Trativa abaixo para no caso de uma alteracao do campo trazer todos
//os dados que foram selecionados anteriormente.                    
//==========================================================================
*/
If Len(AllTrim(&MvRet)) == 0
	
	MvPar:= PadR(AllTrim(StrTran(&MvRet,_cSeparador,"")),Len(aCat))
	&MvRet:= PadR(AllTrim(StrTran(&MvRet,_cSeparador,"")),Len(aCat))
	
Else
	
	MvPar:= AllTrim(StrTran(&MvRet,_cSeparador,"/"))
	
EndIf

/*
//==========================================================================
//Somente altera o conteudo caso o usuario clique no botao ok
//==========================================================================
*/
If Type("_cSeparador") <> "C"
   _cSeparador:=";"
EndIf 

//Executa funcao que monta tela de opcoes
If f_Opcoes(@MvPar,cTitulo,aCat,MvParDef,12,49,.F.,nTam,nMaxSelect)
	
	//Tratamento para separar retorno com barra 
	&MvRet := ""
	For i:=1 to Len(MvPar) step nTam
		If !(SubStr(MvPar,i,1) $ " |*")
			&MvRet  += SubStr(MvPar,i,nTam) + _cSeparador
		EndIf
	Next i
	
	//Trata para tirar o ultimo caracter
	&MvRet := SubStr(&MvRet,1,Len(&MvRet)-1)
	
EndIf

cRetF3:=&MvRet

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf
FWRestArea(_aarea)

Return(.T.)         


/*
===============================================================================================================================
Programa----------: AEST031S
Autor-------------: Josue Danich
Data da Criacao---: 29/10/2015
Descricao---------: Auxiliar para consulta do cadastro de fornecedores
Parametros--------: Nenhum
Retorno-----------: .T.
===============================================================================================================================
*/
User Function AEST031S()

Local cGrpcus := ""
Local _lRet	:= .F.
Local _aarea	:= FWGetArea()

cGrpCus:=" SELECT A2_COD, A2_LOJA
cGrpCus+="  FROM " + RETSQLNAME("SA2") + " A2"
cGrpCus+=" WHERE D_E_L_E_T_ = ' ' "
cGrpCus+=" AND A2_FILIAL = '"+xFilial("SA2")+"' "
cGrpCus+=" AND A2_MSBLQL = '2'""
cGrpCus+=" AND A2_COD = '" + AllTrim(SA2->A2_COD) + "'"
cGrpCus+=" ORDER BY A2_LOJA"

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf

cGrpCus := ChangeQuery(cGrpCus)
MPSysOpenQuery(cGrpCus,"TRB")

If TRB->(!Eof()) .And. TRB->A2_LOJA == SA2->A2_LOJA
	_lRet := .T.
EndIf

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf
FWRestArea(_aarea)

Return(_lRet)         

/*
===============================================================================================================================
Programa----------: AEST031R
Autor-------------: Josue Danich
Data da Criacao---: 29/10/2015
Descricao---------: Auxiliar para consulta do cadastro de clientes
Parametros--------: Nenhum
Retorno-----------: .T.
===============================================================================================================================
*/
User Function AEST031R()

Local cGrpcus := ""
Local _lRet	:= .F.
Local _aarea	:= FWGetArea()

cGrpCus:=" SELECT A1_COD, A1_LOJA
cGrpCus+="  FROM " + RETSQLNAME("SA12") + " A1"
cGrpCus+=" WHERE D_E_L_E_T_ = ' ' "
cGrpCus+=" AND A1_FILIAL = '"+xFilial("SA1")+"' "
cGrpCus+=" AND A1_MSBLQL = '2'""
cGrpCus+=" AND A1_COD = '" + AllTrim(SA1->A1_COD) + "'"
cGrpCus+=" ORDER BY A1_LOJA"

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf

cGrpCus := ChangeQuery(cGrpCus)
MPSysOpenQuery(cGrpCus,"TRB")

If TRB->(!Eof()) .And. TRB->A1_LOJA == SA1->A1_LOJA
	_lRet := .T.
EndIf

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf
FWRestArea(_aarea)

Return(_lRet)         

/*
===============================================================================================================================
Programa----------: AEST031B
Autor-------------: Josue Danich
Data da Criacao---: 29/10/2015
Descricao---------: Consulta múltipla para o cadastro de cfops
Parametros--------: Nenhum
Retorno-----------: .T.
===============================================================================================================================
*/
User Function AEST031B()

Local i := 0,_nI
Local _aMvpar		:= {}
Local _aMVAju		:= {}
Local _aMvOri		:= {}
Local _aarea	:= FWGetArea()

Private nTam      := 0
Private aCat      := {}
Private MvRet     := AllTrim(ReadVar())
Private MvPar     := ""
Private cTitulo   := ""
Private MvParDef  := ""

#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

//Tratamento para carregar variaveis da lista de opcoes
nTam:=4
nMaxSelect := 14 //75 / 3
cTitulo :="Cfop"

cGrpCus := " SELECT "
cGrpCus += " X5_CHAVE CHAVE,X5_DESCRI DESCRI"
cGrpCus += " FROM "+ RetSqlName("SX5") +" X5 "
cGrpCus += " WHERE D_E_L_E_T_ = ' ' "
cGrpCus += " AND X5_TABELA  = '13' "
cGrpCus += " AND X5_TABELA >= '0'"
cGrpCus += " AND X5_FILIAL  = '" + xFilial("SX5") + "'"	
cGrpCus += " ORDER BY X5_CHAVE"

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf

cGrpCus := ChangeQuery(cGrpCus)
MPSysOpenQuery(cGrpCus,"TRB")

While TRB->(!Eof())

	MvParDef += StrZero( Val(TRB->CHAVE), ntam) 
	aAdd(aCat,AllTrim(TRB->DESCRI))
	aAdd(_aMvAju, StrZero( Val(TRB->CHAVE), ntam)  )
	aAdd(_aMvOri, AllTrim(TRB->CHAVE)  )
	TRB->(DBSkip())

EndDo

/*
//==========================================================================
//Trativa abaixo para no caso de uma alteracao do campo trazer todos
//os dados que foram selecionados anteriormente.                    
//==========================================================================
*/
If Type("_cSeparador") <> "C"
   _cSeparador:=";"
EndIf 

If Len(AllTrim(&MvRet)) == 0
	
	MvPar:= PadR(AllTrim(StrTran(&MvRet,_cSeparador,"")),Len(aCat))
	&MvRet:= PadR(AllTrim(StrTran(&MvRet,_cSeparador,"")),Len(aCat))
	
Else
	
	_aMvPar := StrTokArr( &MvRet, _cSeparador )
	&MvRet := ""

	For _nI := 1 to Len(_aMvPar)
	
		&MvRet += StrZero( Val(_aMvPar[_nI]), ntam) + _cSeparador		
	Next
	
	&MvRet := SubStr(&MvRet,1,Len(&MvRet)-1)
	
	MvPar:= AllTrim(StrTran(&MvRet,_cSeparador,"/"))
	
EndIf

/*
//==========================================================================
//Somente altera o conteudo caso o usuario clique no botao ok
//==========================================================================
*/

//Executa funcao que monta tela de opcoes
If f_Opcoes(@MvPar,cTitulo,aCat,MvParDef,12,49,.F.,nTam,nMaxSelect)
	
	//Tratamento para separar retorno com barra 
	&MvRet := ""

	For i:=1 to Len(MvPar) step nTam

		If !(SubStr(MvPar,i,1) $ " |*")
 
           If aScan(_aMvAju, AllTrim(SubStr(MvPar,i,nTam ))) > 0
           
    			&MvRet  += _aMvOri[aScan(_aMvAju, AllTrim(SubStr(MvPar,i,nTam )))] + _cSeparador
			
			Else
			
				&MvRet  += AllTrim(SubStr(MvPar,i,nTam)) + _cSeparador
				
			EndIf

		EndIf

	Next i
	
	//Trata para tirar o ultimo caracter
	&MvRet := SubStr(&MvRet,1,Len(&MvRet)-1)
	
EndIf

cRetF3:=&MvRet

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf
FWRestArea(_aarea)

Return(.T.)

/*
===============================================================================================================================
Programa----------: AEST031W
Autor-------------: Josue Danich
Data da Criacao---: 29/10/2015
Descricao---------: Consulta múltipla para o cadastro de centro de custo
Parametros--------: Nenhum
Retorno-----------: .T.
===============================================================================================================================
*/
User Function AEST031W()

Local i := 0,_nI
Local _aMvpar		:= {}
Local _aMVAju		:= {}
Local _aMvOri		:= {}
Local _aarea	:= FWGetArea()

Private nTam      := 0
Private aCat      := {}
Private MvRet     := AllTrim(ReadVar())
Private MvPar     := ""
Private cTitulo   := ""
Private MvParDef  := ""

#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

//Tratamento para carregar variaveis da lista de opcoes
nTam:=8
//nMaxSelect := 14 //75 / 3
cTitulo :="Centros de Custo"


cGrpCus:=" SELECT CTT_CUSTO, CTT_DESC01 FROM " + retsqlname("CTT")
cGrpCus+=" WHERE D_E_L_E_T_ = ' ' "
cGrpCus+=" AND CTT_FILIAL = '"+xFilial("CTT")+"' "
cGrpCus+=" AND CTT_BLOQ  = '2' "
cGrpCus+=" AND CTT_CLASSE = '2' "
cGrpCus+=" ORDER BY CTT_CUSTO"


If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf

cGrpCus := ChangeQuery(cGrpCus)
MPSysOpenQuery(cGrpCus,"TRB")

While TRB->(!Eof())

	MvParDef += StrZero(Val(AllTrim(TRB->CTT_CUSTO)),ntam)
	aAdd(aCat,StrTran(AllTrim(TRB->CTT_DESC01),"-","") )
	aAdd(_aMvAju, LEFT(TRB->CTT_CUSTO,nTam)  )
	aAdd(_aMvOri, AllTrim(TRB->CTT_CUSTO)  )
	TRB->(DBSkip())
EndDo
nMaxSelect := 50//Len(aCat)
/*
//==========================================================================
//Trativa abaixo para no caso de uma alteracao do campo trazer todos
//os dados que foram selecionados anteriormente.                    
//==========================================================================
*/
If Type("_cSeparador") <> "C"
   _cSeparador:=";"
EndIf 
If Len(AllTrim(&MvRet)) == 0
	
	MvPar:= PadR(AllTrim(StrTran(&MvRet,_cSeparador,"")),Len(aCat))
	&MvRet:= PadR(AllTrim(StrTran(&MvRet,_cSeparador,"")),Len(aCat))
	
Else
	
	_aMvPar := StrTokArr( &MvRet, _cSeparador )
	&MvRet := ""

	For _nI := 1 to Len(_aMvPar)
	
		&MvRet += StrZero( Val(_aMvPar[_nI]), ntam) + _cSeparador		
	Next
	
	&MvRet := SubStr(&MvRet,1,Len(&MvRet)-1)
	
	MvPar:= AllTrim(StrTran(&MvRet,_cSeparador,"/"))
	
EndIf


/*
//==========================================================================
//Somente altera o conteudo caso o usuario clique no botao ok
//==========================================================================
*/

If Type("_cSeparador") <> "C"
   _cSeparador:=";"
EndIf 
//Executa funcao que monta tela de opcoes
If f_Opcoes(@MvPar,cTitulo,aCat,MvParDef,12,49,.F.,nTam,nMaxSelect)
	
	//Tratamento para separar retorno com barra 
	&MvRet := ""

	For i:=1 to Len(MvPar) step nTam

		If !(SubStr(MvPar,i,1) $ " |*")
 
           If aScan(_aMvAju, AllTrim(SubStr(MvPar,i,nTam ))) > 0
           
    			&MvRet  += _aMvOri[aScan(_aMvAju, AllTrim(SubStr(MvPar,i,nTam )))] + _cSeparador
			
			Else
			
				&MvRet  += AllTrim(SubStr(MvPar,i,nTam)) + _cSeparador
				
			EndIf

		EndIf

	Next i
	
	//Trata para tirar o ultimo caracter
	&MvRet := SubStr(&MvRet,1,Len(&MvRet)-1)
	
EndIf

cRetF3:=&MvRet

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf
FWRestArea(_aarea)

Return(.T.)

/*
===============================================================================================================================
Programa----------: AEST031F
Autor-------------: Josue Danich
Data da Criacao---: 29/10/2015
Descricao---------: Consulta múltipla para o cadastro de verbas
Parametros--------: Nenhum
Retorno-----------: .T.
===============================================================================================================================
*/
User Function AEST031F()

Local i := 0
Local _aarea	:= FWGetArea()

Private nTam      := 0
Private aCat      := {}
Private MvRet     := AllTrim(ReadVar())
Private MvPar     := ""
Private cTitulo   := ""
Private MvParDef  := ""

#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

//Tratamento para carregar variaveis da lista de opcoes
nTam:=3
nMaxSelect := 14 //75 / 3
cTitulo :="Verbas"


cGrpCus:=" SELECT RV_COD, RV_DESC FROM " + retsqlname("SRV")
cGrpCus+=" WHERE D_E_L_E_T_ = ' ' "
cGrpCus+=" AND RV_COD >= '0'"
cGrpCus+=" AND RV_FILIAL = '"+xFilial("SRV")+"' "
cGrpCus+=" ORDER BY RV_COD"


If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf

cGrpCus := ChangeQuery(cGrpCus)
MPSysOpenQuery(cGrpCus,"TRB")

While TRB->(!Eof())
	MvParDef += AllTrim(TRB->RV_COD)
	aAdd(aCat,AllTrim(TRB->RV_DESC))
	TRB->(DBSkip())
EndDo

/*
//==========================================================================
//Trativa abaixo para no caso de uma alteracao do campo trazer todos
//os dados que foram selecionados anteriormente.                    
//==========================================================================
*/
If Type("_cSeparador") <> "C"
   _cSeparador:=";"
EndIf 
If Len(AllTrim(&MvRet)) == 0
	
	MvPar:= PadR(AllTrim(StrTran(&MvRet,_cSeparador,"")),Len(aCat))
	&MvRet:= PadR(AllTrim(StrTran(&MvRet,_cSeparador,"")),Len(aCat))
	
Else
	
	MvPar:= AllTrim(StrTran(&MvRet,_cSeparador,"/"))
	
EndIf

/*
//==========================================================================
//Somente altera o conteudo caso o usuario clique no botao ok
//==========================================================================
*/

If Type("_cSeparador") <> "C"
   _cSeparador:=";"
EndIf 
//Executa funcao que monta tela de opcoes
If f_Opcoes(@MvPar,cTitulo,aCat,MvParDef,12,49,.F.,nTam,nMaxSelect)
	
	//Tratamento para separar retorno com barra 
	&MvRet := ""
	For i:=1 to Len(MvPar) step nTam
		If !(SubStr(MvPar,i,1) $ " |*")
			&MvRet  += SubStr(MvPar,i,nTam) + _cSeparador
		EndIf
	Next i
	
	//Trata para tirar o ultimo caracter
	&MvRet := SubStr(&MvRet,1,Len(&MvRet)-1)
	
EndIf

cRetF3:=&MvRet

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf
FWRestArea(_aarea)

Return(.T.)

/*
===============================================================================================================================
Programa----------: AEST031Z
Autor-------------: Josue Danich
Data da Criacao---: 29/10/2015
Descricao---------: Consulta múltipla para o cadastro de naturezas
Parametros--------: Nenhum
Retorno-----------: .T.
===============================================================================================================================
*/
User Function AEST031Z()

Local i := 0
Local _aarea	:= FWGetArea()

Private nTam      := 0
Private aCat      := {}
Private MvRet     := AllTrim(ReadVar())
Private MvPar     := ""
Private cTitulo   := ""
Private MvParDef  := ""
//Private TRB := CriaTrab(Nil,.F.)

#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

//Tratamento para carregar variaveis da lista de opcoes
nTam:=6
nMaxSelect := 14 //75 / 3
cTitulo :="Natureza"


cGrpCus:=" SELECT ED_CODIGO, ED_DESCRIC FROM " + retsqlname("SED")
cGrpCus+=" WHERE D_E_L_E_T_ = ' ' "
cGrpCus+=" AND ED_FILIAL = '"+xFilial("SED")+"' "
cGrpCus+=" AND ED_CODIGO >= '0'"
cGrpCus+=" ORDER BY ED_CODIGO"

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf

cGrpCus := ChangeQuery(cGrpCus)
MPSysOpenQuery(cGrpCus,"TRB")

While TRB->(!Eof())
	MvParDef += AllTrim(TRB->ED_CODIGO)
	aAdd(aCat,AllTrim(TRB->ED_DESCRIC))
	TRB->(DBSkip())
EndDo

If Type("_cSeparador") <> "C"
   _cSeparador:=";"
EndIf 
/*
//==========================================================================
//Trativa abaixo para no caso de uma alteracao do campo trazer todos
//os dados que foram selecionados anteriormente.                    
//==========================================================================
*/
If Len(AllTrim(&MvRet)) == 0
	
	MvPar:= PadR(AllTrim(StrTran(&MvRet,_cSeparador,"")),Len(aCat))
	&MvRet:= PadR(AllTrim(StrTran(&MvRet,_cSeparador,"")),Len(aCat))
	
Else
	
	MvPar:= AllTrim(StrTran(&MvRet,_cSeparador,"/"))
	
EndIf

/*
//==========================================================================
//Somente altera o conteudo caso o usuario clique no botao ok
//==========================================================================
*/

//Executa funcao que monta tela de opcoes
If f_Opcoes(@MvPar,cTitulo,aCat,MvParDef,12,49,.F.,nTam,nMaxSelect)
	
	//Tratamento para separar retorno com barra _cSeparador
	&MvRet := ""
	For i:=1 to Len(MvPar) step nTam
		If !(SubStr(MvPar,i,1) $ " |*")
			&MvRet  += SubStr(MvPar,i,nTam) + _cSeparador
		EndIf
	Next i
	
	//Trata para tirar o ultimo caracter
	&MvRet := SubStr(&MvRet,1,Len(&MvRet)-1)
	
EndIf

cRetF3:=&MvRet
If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf
FWRestArea(_aarea)

Return(.T.)

/*
===============================================================================================================================
Programa----------: AEST031C
Autor-------------: Josue Danich
Data da Criacao---: 29/10/2015
Descricao---------: Consulta múltipla para o cadastro de tipos de custos
Parametros--------: Nenhum
Retorno-----------: .T.
===============================================================================================================================
*/
User Function AEST031C()

Local i := 0
Local _aarea	:= FWGetArea()

Private nTam      := 0
Private aCat      := {}
Private MvRet     := AllTrim(ReadVar())
Private MvPar     := ""
Private cTitulo   := ""
Private MvParDef  := ""
//Private TRB := CriaTrab(Nil,.F.)

#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

//Tratamento para carregar variaveis da lista de opcoes
nTam:=6
nMaxSelect := 14 //75 / 3
cTitulo :="Tipo Custo"

cGrpCus:=" SELECT ZL5_CODGRP, ZL5_DESGRP FROM " + RetSqlName("ZL5")
cGrpCus+=" WHERE D_E_L_E_T_ = ' ' "
cGrpCus+=" AND ZL5_FILIAL = '"+xFilial("ZL5")+"' "
cGrpCus+=" AND ZL5_CODGRP >= '0'"
cGrpCus += " ORDER BY ZL5_CODGRP "

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf

cGrpCus := ChangeQuery(cGrpCus)
MPSysOpenQuery(cGrpCus,"TRB")

While TRB->(!Eof())
	MvParDef += AllTrim(TRB->ZL5_CODGRP)
	aAdd(aCat,AllTrim(TRB->ZL5_DESGRP))
	TRB->(DBSkip())
EndDo

/*
//==========================================================================
//Trativa abaixo para no caso de uma alteracao do campo trazer todos
//os dados que foram selecionados anteriormente.                    
//==========================================================================
*/
If Type("_cSeparador") <> "C"
   _cSeparador:=";"
EndIf 
If Len(AllTrim(&MvRet)) == 0
	
	MvPar:= PadR(AllTrim(StrTran(&MvRet,_cSeparador,"")),Len(aCat))
	&MvRet:= PadR(AllTrim(StrTran(&MvRet,_cSeparador,"")),Len(aCat))
	
Else
	
	MvPar:= AllTrim(StrTran(&MvRet,_cSeparador,"/"))
	
EndIf

/*
//==========================================================================
//Somente altera o conteudo caso o usuario clique no botao ok
//==========================================================================
*/
If Type("_cSeparador") <> "C"
   _cSeparador:=";"
EndIf 

//Executa funcao que monta tela de opcoes
If f_Opcoes(@MvPar,cTitulo,aCat,MvParDef,12,49,.F.,nTam,nMaxSelect)
	
	//Tratamento para separar retorno com barra _cSeparador
	&MvRet := ""
	For i:=1 to Len(MvPar) step nTam
		If !(SubStr(MvPar,i,1) $ " |*")
			&MvRet  += SubStr(MvPar,i,nTam) + _cSeparador
		EndIf
	Next i
	
	//Trata para tirar o ultimo caracter
	&MvRet := SubStr(&MvRet,1,Len(&MvRet)-1)
	
EndIf

cRetF3:=&MvRet

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf
FWRestArea(_aarea)

Return(.T.)

/*
===============================================================================================================================
Programa----------: AEST031Q
Autor-------------: Josue Danich
Data da Criacao---: 29/10/2015
Descricao---------: Consulta múltipla para prefixos de títulos financeiro
Parametros--------: Nenhum
Retorno-----------: .T.
===============================================================================================================================
*/
User Function AEST031Q()

Local i := 0
Local _aarea	:= FWGetArea()

Private nTam      := 0
Private aCat      := {}
Private MvRet     := AllTrim(ReadVar())
Private MvPar     := ""
Private cTitulo   := ""
Private MvParDef  := ""

#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

//Tratamento para carregar variaveis da lista de opcoes
nTam:=10
nMaxSelect := 14 //75 / 3
cTitulo :="Prefixo Titulo"


cGrpCus:=" SELECT DISTINCT E5_PREFIXO AS PREFIXO "
cGrpCus+=" FROM " + retsqlname("SE5") + " E5" 
cGrpCus+=" WHERE E5_DTDIGIT >= '" + (DToS(Date() - 90)) + "'"
cGrpCus+=" AND D_E_L_E_T_ = ' ' "
cGrpCus+=" AND E5_FILIAL = '"+xFilial("SE5")+"' "
cGrpCus+=" GROUP BY E5_PREFIXO "
cGrpCus+=" ORDER BY E5_PREFIXO "

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf

cGrpCus := ChangeQuery(cGrpCus)
MPSysOpenQuery(cGrpCus,"TRB")

If TRB->(Eof())
	U_ITMsg("Nao ha registros para a data maior ou igual a " + (DToS(Date() - 90)),'Atenção!',,1)
EndIf

While TRB->(!Eof())
	MvParDef += (TRB->PREFIXO) + Space(10 - Len(TRB->PREFIXO))
	aAdd(aCat,(TRB->PREFIXO))
	TRB->(DBSkip())
EndDo

/*
//==========================================================================
//Trativa abaixo para no caso de uma alteracao do campo trazer todos
//os dados que foram selecionados anteriormente.                    
//==========================================================================
*/
If Type("_cSeparador") <> "C"
   _cSeparador:=";"
EndIf 
If Len(AllTrim(&MvRet)) == 0
	
	MvPar:= PadR(AllTrim(StrTran(&MvRet,_cSeparador,"")),Len(aCat))
	&MvRet:= PadR(AllTrim(StrTran(&MvRet,_cSeparador,"")),Len(aCat))
	
Else
	
	MvPar:= AllTrim(StrTran(&MvRet,_cSeparador,"/"))
	
EndIf

/*
//==========================================================================
//Somente altera o conteudo caso o usuario clique no botao ok
//==========================================================================
*/
If Type("_cSeparador") <> "C"
   _cSeparador:=";"
EndIf 

//Executa funcao que monta tela de opcoes
If f_Opcoes(@MvPar,cTitulo,aCat,MvParDef,12,49,.F.,nTam,nMaxSelect)
	
	//Tratamento para separar retorno com barra _cSeparador
	&MvRet := ""
	For i:=1 to Len(MvPar) step nTam
		If !(SubStr(MvPar,i,1) $ " |*")
			&MvRet  += SubStr(MvPar,i,nTam) + _cSeparador
		EndIf
	Next i
	
	//Trata para tirar o ultimo caracter
	&MvRet := SubStr(&MvRet,1,Len(&MvRet)-1)
	
EndIf

cRetF3:=&MvRet

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf
FWRestArea(_aarea)

Return(.T.)

/*
===============================================================================================================================
Programa----------: AEST031X
Autor-------------: Josue Danich
Data da Criacao---: 29/10/2015
Descricao---------: Consulta múltipla para tipos de títulos financeiro
Parametros--------: Nenhum
Retorno-----------: .T.
===============================================================================================================================
*/
User Function AEST031X()

Local i := 0
Local _aarea	:= FWGetArea()

Private nTam      := 0
Private aCat      := {}
Private MvRet     := AllTrim(ReadVar())
Private MvPar     := ""
Private cTitulo   := ""
Private MvParDef  := ""

#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

//Tratamento para carregar variaveis da lista de opcoes
nTam:=10
nMaxSelect := 14 //75 / 3
cTitulo :="Tipo Titulo"


cGrpCus:=" SELECT DISTINCT E5_TIPO AS TIPO "
cGrpCus+=" FROM " + retsqlname("SE5") + " E5" 
cGrpCus+=" WHERE E5_DTDIGIT >= '" + (DToS(Date() - 90)) + "'"
cGrpCus+=" AND D_E_L_E_T_ = ' ' "
cGrpCus+=" AND E5_FILIAL = '"+xFilial("SE5")+"' "
cGrpCus+=" GROUP BY E5_TIPO "
cGrpCus+=" ORDER BY E5_TIPO "

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf

cGrpCus := ChangeQuery(cGrpCus)
MPSysOpenQuery(cGrpCus,"TRB")

If TRB->(Eof())
	U_ITMsg("Nao ha registros para a data maior ou igual a " + (DToS(Date() - 90)),'Atenção!',,1)
EndIf

While TRB->(!Eof())
	MvParDef += (TRB->TIPO) + Space(10-Len(TRB->TIPO))
	aAdd(aCat,(TRB->TIPO))
	TRB->(DBSkip())
EndDo

/*
//==========================================================================
//Trativa abaixo para no caso de uma alteracao do campo trazer todos
//os dados que foram selecionados anteriormente.                    
//==========================================================================
*/
If Type("_cSeparador") <> "C"
   _cSeparador:=";"
EndIf 
If Len(AllTrim(&MvRet)) == 0
	
	MvPar:= PadR(AllTrim(StrTran(&MvRet,_cSeparador,"")),Len(aCat))
	&MvRet:= PadR(AllTrim(StrTran(&MvRet,_cSeparador,"")),Len(aCat))
	
Else
	
	MvPar:= AllTrim(StrTran(&MvRet,_cSeparador,"/"))
	
EndIf

/*
//==========================================================================
//Somente altera o conteudo caso o usuario clique no botao ok
//==========================================================================
*/
If Type("_cSeparador") <> "C"
   _cSeparador:=";"
EndIf 
//Executa funcao que monta tela de opcoes
If f_Opcoes(@MvPar,cTitulo,aCat,MvParDef,12,49,.F.,nTam,nMaxSelect)
	
	//Tratamento para separar retorno com barra _cSeparador
	&MvRet := ""
	For i:=1 to Len(MvPar) step nTam
		If !(SubStr(MvPar,i,1) $ " |*")
			&MvRet  += SubStr(MvPar,i,nTam) + _cSeparador
		EndIf
	Next i
	
	//Trata para tirar o ultimo caracter
	&MvRet := SubStr(&MvRet,1,Len(&MvRet)-1)
	
EndIf

cRetF3:=&MvRet

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf
FWRestArea(_aarea)

Return(.T.)

/*
===============================================================================================================================
Programa----------: AEST031J
Autor-------------: Josue Danich
Data da Criacao---: 29/10/2015
Descricao---------: Consulta múltipla para tipos de produtos
Parametros--------: Nenhum
Retorno-----------: .T.
===============================================================================================================================
*/
User Function AEST031J()

Local i := 0
Local _aarea	:= FWGetArea()

Private nTam      := 0
Private aCat      := {}
Private MvRet     := AllTrim(ReadVar())
Private MvPar     := ""
Private cTitulo   := ""
Private MvParDef  := ""

#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

//Tratamento para carregar variaveis da lista de opcoes
nTam:=2
If FUNNAME() = "ACFG003"
   nMaxSelect := 26
Else
   nMaxSelect := 14 //75 / 3
EndIf
cTitulo :="Tipos de produtos"


cGrpCus := " SELECT "
cGrpCus += " X5_CHAVE CHAVE,X5_DESCRI DESCRI "
cGrpCus += " FROM "+ RetSqlName("SX5") +" X5 "
cGrpCus += " WHERE "
cGrpCus += "     D_E_L_E_T_ = ' ' "
cGrpCus += " AND X5_TABELA  = '02' "
cGrpCus += " AND X5_CHAVE >= '0'"
cGrpCus += " AND X5_FILIAL  = '" + xFilial("SX5") + "'"	
cGrpCus += " ORDER BY X5_CHAVE"

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf

cGrpCus := ChangeQuery(cGrpCus)
MPSysOpenQuery(cGrpCus,"TRB")

While TRB->(!Eof())
	MvParDef += AllTrim(TRB->CHAVE) 
	aAdd(aCat,AllTrim(TRB->DESCRI))
	TRB->(DBSkip())
EndDo

/*
//==========================================================================
//Trativa abaixo para no caso de uma alteracao do campo trazer todos
//os dados que foram selecionados anteriormente.                    
//==========================================================================
*/
If Type("_cSeparador") <> "C"
   _cSeparador:=";"
EndIf 
If Len(AllTrim(&MvRet)) == 0
	
	MvPar:= PadR(AllTrim(StrTran(&MvRet,_cSeparador,"")),Len(aCat))
	&MvRet:= PadR(AllTrim(StrTran(&MvRet,_cSeparador,"")),Len(aCat))
	
Else
	
	MvPar:= AllTrim(StrTran(&MvRet,_cSeparador,"/"))
	
EndIf

/*
//==========================================================================
//Somente altera o conteudo caso o usuario clique no botao ok
//==========================================================================
*/
If Type("_cSeparador") <> "C"
   _cSeparador:=";"
EndIf 

//Executa funcao que monta tela de opcoes
If f_Opcoes(@MvPar,cTitulo,aCat,MvParDef,12,49,.F.,nTam,nMaxSelect)
	
	//Tratamento para separar retorno com barra _cSeparador
	&MvRet := ""
	For i:=1 to Len(MvPar) step nTam
		If !(SubStr(MvPar,i,1) $ " |*")
			&MvRet  += AllTrim(SubStr(MvPar,i,nTam)) + _cSeparador
		EndIf
	Next i
	
	//Trata para tirar o ultimo caracter
	&MvRet := SubStr(&MvRet,1,Len(&MvRet)-1)
	
EndIf

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf
FWRestArea(_aarea)

Return(.T.)

/*
===============================================================================================================================
Programa----------: AEST031O
Autor-------------: Josue Danich
Data da Criacao---: 29/10/2015
Descricao---------: Consulta múltipla para CF da tabela D3
Parametros--------: Nenhum
Retorno-----------: .T.
===============================================================================================================================
*/
User Function AEST031O()

Local i := 0
Local _aarea	:= FWGetArea()

Private nTam      := 0

Private aCat      := {}
Private MvRet     := AllTrim(ReadVar())
Private MvPar     := ""
Private cTitulo   := ""
Private MvParDef  := ""

#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

//Tratamento para carregar variaveis da lista de opcoes
nTam:=3
nMaxSelect := 14 //75 / 3
cTitulo :="CF de movimento interno"


cGrpCus:= " SELECT X5_CHAVE AS TIPO, X5_DESCRI AS DESCR"
cGrpCus+= "		FROM "+ RetSqlName("SX5") +" X5 "
cGrpCus+= " 		WHERE D_E_L_E_T_ = ' ' "
cGrpCus+= " 		AND X5_TABELA  = 'ZY' "
cGrpCus+= "      AND X5_CHAVE >= '0'"
cGrpCus+= " 		AND X5_FILIAL  = '" + xFilial("SX5") + "'"	
cGrpCus+= " ORDER BY X5_CHAVE"

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf

cGrpCus := ChangeQuery(cGrpCus)
MPSysOpenQuery(cGrpCus,"TRB")

If TRB->(Eof())
	U_ITMsg("Nao ha registros para a tabela ZY ",'Atenção!',,1)
EndIf

While TRB->(!Eof())
	MvParDef += AllTrim(TRB->TIPO)
	aAdd(aCat,AllTrim(TRB->DESCR))
	TRB->(DBSkip())
EndDo

/*
//==========================================================================
//Trativa abaixo para no caso de uma alteracao do campo trazer todos
//os dados que foram selecionados anteriormente.                    
//==========================================================================
*/
If Type("_cSeparador") <> "C"
   _cSeparador:=";"
EndIf 
If Len(AllTrim(&MvRet)) == 0
	
	MvPar:= PadR(AllTrim(StrTran(&MvRet,_cSeparador,"")),Len(aCat))
	&MvRet:= PadR(AllTrim(StrTran(&MvRet,_cSeparador,"")),Len(aCat))
	
Else
	
	MvPar:= AllTrim(StrTran(&MvRet,_cSeparador,"/"))
	
EndIf

/*
//==========================================================================
//Somente altera o conteudo caso o usuario clique no botao ok
//==========================================================================
*/
If Type("_cSeparador") <> "C"
   _cSeparador:=";"
EndIf 

//Executa funcao que monta tela de opcoes
If f_Opcoes(@MvPar,cTitulo,aCat,MvParDef,12,49,.F.,nTam,nMaxSelect)
	
	//Tratamento para separar retorno com barra _cSeparador
	&MvRet := ""
	For i:=1 to Len(MvPar) step nTam
		If !(SubStr(MvPar,i,1) $ " |*")
			&MvRet  += SubStr(MvPar,i,nTam) + _cSeparador
		EndIf
	Next i
	
	//Trata para tirar o ultimo caracter
	&MvRet := SubStr(&MvRet,1,Len(&MvRet)-1)
	
EndIf

cRetF3:=SubStr(&MvRet,1,Len(&MvRet)-1)
If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf
FWRestArea(_aarea)

Return(.T.)

/*
===============================================================================================================================
Programa----------: AEST031A
Autor-------------: Josue Danich
Data da Criacao---: 13/11/2015
Descricao---------: Consulta múltipla TES
Parametros--------: Nenhum
Retorno-----------: .T.
===============================================================================================================================
*/
User Function AEST031A()

Local i				:= 0
Local _aarea	:= FWGetArea()

Private nTam		:= 0
Private aCat		:= {}
Private MvRet		:= AllTrim(ReadVar())
Private MvPar		:= ""
Private cTitulo		:= ""
Private MvParDef	:= ""

#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

//Tratamento para carregar variaveis da lista de opcoes
nTam		:= 3
nMaxSelect	:= 24 //14 * 7 = 98 (cod(6) +_cSeparador) = 7
cTitulo		:= "TES - FIN - ICM - CF     -   DESC "      

cGrpCus:=" SELECT	F4.F4_CODIGO,	"
cGrpCus+=" 		F4.F4_DUPLIC,	"
cGrpCus+=" 		F4.F4_ICM, 	"
cGrpCus+=" 		F4.F4_CF, 	"
cGrpCus+=" 		F4.F4_TEXTO	"
cGrpCus+=" FROM " + retsqlname("SF4") + " F4" 
cGrpCus+=" WHERE D_E_L_E_T_ = ' ' "
cGrpCus+=" AND F4.F4_CODIGO >= '0'"
cGrpCus+=" AND F4.F4_FILIAL = '"+xFilial("SF4")+"' "
cGrpCus+=" ORDER BY F4.F4_CODIGO "

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf

cGrpCus := ChangeQuery(cGrpCus)
MPSysOpenQuery(cGrpCus,"TRB")

While TRB->(!Eof())

	MvParDef += AllTrim(TRB->F4_CODIGO)
	aAdd(aCat,"  " + PadR(TRB->F4_DUPLIC,3," ") + '  -   ' + TRB->F4_ICM + '  - ' + TRB->F4_CF  + '  -  ' + TRB->F4_TEXTO) 
		
	TRB->(DBSkip())
	
EndDo                                    

//========================================================================
//Trativa abaixo para no caso de uma alteracao do campo trazer todos
//os dados que foram selecionados anteriormente.                    
//========================================================================
If Type("_cSeparador") <> "C"
   _cSeparador:=";"
EndIf 

If Len(AllTrim(&MvRet)) == 0                              

	MvPar:= PadR(AllTrim(StrTran(&MvRet,_cSeparador,"")),Len(aCat))
	&MvRet:= PadR(AllTrim(StrTran(&MvRet,_cSeparador,"")),Len(aCat))
	
Else

	MvPar:= AllTrim(StrTran(&MvRet,_cSeparador,"/"))

EndIf

//Executa funcao que monta tela de opcoes
If f_Opcoes(@MvPar,cTitulo,aCat,MvParDef,12,49,.F.,nTam,nMaxSelect)        

	//Tratamento para separar retorno com barra _cSeparador
	&MvRet := ""
	For i:=1 to Len(MvPar) step nTam
		If !(SubStr(MvPar,i,1) $ " |*")
			&MvRet  += SubStr(MvPar,i,nTam) + _cSeparador
		EndIf
	Next i
	
	//Trata para tirar o ultimo caracter
	&MvRet := SubStr(&MvRet,1,Len(&MvRet)-1) 

EndIf     

cRetF3:=&MvRet

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf
FWRestArea(_aarea)

Return(.T.)

/*
===============================================================================================================================
Programa----------: AEST0316
Autor-------------: Josue Danich
Data da Criacao---: 29/10/2015
Descricao---------: Consulta múltipla para o tipos de nota fiscal
Parametros--------: Nenhum
Retorno-----------: .T.
===============================================================================================================================
*/
User Function AEST0316()

Local i := 0
Local _aarea	:= FWGetArea()

Private nTam      := 0
Private aCat      := {}
Private MvRet     := AllTrim(ReadVar())
Private MvPar     := ""
Private cTitulo   := ""
Private MvParDef  := ""
//Private TRB := CriaTrab(Nil,.F.)

#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

//Tratamento para carregar variaveis da lista de opcoes
nTam:=1
nMaxSelect := 14 //75 / 3
cTitulo :="Tipo Nota"


cGrpCus:=" SELECT DISTINCT D1_TIPO AS TIPO, "
cGrpCus+= "( SELECT X5_DESCRI "
cGrpCus+= "		FROM "+ RetSqlName("SX5") +" X5 "
cGrpCus+= " 		WHERE "
cGrpCus+= "     D_E_L_E_T_ = ' ' "
cGrpCus+= " 		AND X5_TABELA  = 'ZX' "
cGrpCus+= " 		AND X5_FILIAL  = '" + xFilial("SX5") + "'"	
cGrpCus+= " 		AND X5_CHAVE  = D1.D1_TIPO"
cGrpCus+= " 		AND ROWNUM = 1) AS DESCR"
cGrpCus+=" FROM " + retsqlname("SD1") + " D1" 
cGrpCus+=" WHERE D1_EMISSAO >= '" + (DToS(Date() - 90)) + "'"
cGrpCus+=" AND D_E_L_E_T_ = ' ' "
cGrpCus+=" AND D1_FILIAL = '"+xFilial("SD1")+"' "
cGrpCus+=" AND D1_TIPO >= '0'"
cGrpCus+=" GROUP BY D1_TIPO "
cGrpCus+=" UNION"
cGrpCus+=" SELECT DISTINCT D2_TIPO AS TIPO, "
cGrpCus+= "( SELECT X5_DESCRI "
cGrpCus+= "		FROM "+ RetSqlName("SX5") +" X5 "
cGrpCus+= " 		WHERE "
cGrpCus+= "     D_E_L_E_T_ = ' ' "
cGrpCus+= " 		AND X5_TABELA  = 'ZX' "
cGrpCus+= " 		AND X5_FILIAL  = '" + xFilial("SX5") + "'"	
cGrpCus+= " 		AND X5_CHAVE  = D2.D2_TIPO"
cGrpCus+= " 		AND ROWNUM = 1) AS DESCR"
cGrpCus+=" FROM " + retsqlname("SD2") + " D2" 
cGrpCus+=" WHERE D2_EMISSAO >= '" + (DToS(Date() - 90)) + "'"
cGrpCus+=" AND D_E_L_E_T_ = ' ' "
cGrpCus+=" AND D2_TIPO >= '0'"
cGrpCus+=" AND D2_FILIAL = '"+xFilial("SD2")+"' "
cGrpCus+=" GROUP BY D2_TIPO "

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf

cGrpCus := ChangeQuery(cGrpCus)
MPSysOpenQuery(cGrpCus,"TRB")

If TRB->(Eof())
	U_ITMsg("Nao ha registros para a data maior ou igual a " + (DToS(Date() - 90)),'Atenção!',,1)
EndIf

While TRB->(!Eof())
	MvParDef += AllTrim(TRB->TIPO)
	aAdd(aCat,AllTrim(TRB->DESCR))
	TRB->(DBSkip())
EndDo

/*
//==========================================================================
//Trativa abaixo para no caso de uma alteracao do campo trazer todos
//os dados que foram selecionados anteriormente.                    
//==========================================================================
*/
If Type("_cSeparador") <> "C"
   _cSeparador:=";"
EndIf 
If Len(AllTrim(&MvRet)) == 0
	
	MvPar:= PadR(AllTrim(StrTran(&MvRet,_cSeparador,"")),Len(aCat))
	&MvRet:= PadR(AllTrim(StrTran(&MvRet,_cSeparador,"")),Len(aCat))
	
Else
	
	MvPar:= AllTrim(StrTran(&MvRet,_cSeparador,"/"))
	
EndIf

/*
//==========================================================================
//Somente altera o conteudo caso o usuario clique no botao ok
//==========================================================================
*/
If Type("_cSeparador") <> "C"
   _cSeparador:=";"
EndIf 

//Executa funcao que monta tela de opcoes
If f_Opcoes(@MvPar,cTitulo,aCat,MvParDef,12,49,.F.,nTam,nMaxSelect)
	
	//Tratamento para separar retorno com barra _cSeparador
	&MvRet := ""
	For i:=1 to Len(MvPar) step nTam
		If !(SubStr(MvPar,i,1) $ " |*")
			&MvRet  += SubStr(MvPar,i,nTam) + _cSeparador
		EndIf
	Next i
	
	//Trata para tirar o ultimo caracter
	&MvRet := SubStr(&MvRet,1,Len(&MvRet)-1)
	
EndIf

cRetF3:=&MvRet

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf
FWRestArea(_aarea)

Return(.T.)

/*
===============================================================================================================================
Programa----------: MEST009L
Autor-------------: Josue Danich
Data da Criacao---: 29/10/2015
Descricao---------: Consulta múltipla para o tipos de nota fiscal
Parametros--------: Nenhum
Retorno-----------: .T.
===============================================================================================================================
*/
User Function MEST009L()

Local i := 0
Local _aarea	:= FWGetArea()

Private nTam      := 0
Private aCat      := {}
Private MvRet     := AllTrim(ReadVar())
Private MvPar     := ""
Private cTitulo   := ""
Private MvParDef  := ""
//Private TRB := CriaTrab(Nil,.F.)

#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

//Tratamento para carregar variaveis da lista de opcoes
nTam:=1
nMaxSelect := 14 //75 / 3
cTitulo :="Tipo Nota"


cGrpCus:=" SELECT DISTINCT D1_TIPO AS TIPO, "
cGrpCus+= "( SELECT X5_DESCRI "
cGrpCus+= "		FROM "+ RetSqlName("SX5") +" X5 "
cGrpCus+= " 		WHERE "
cGrpCus+= "     D_E_L_E_T_ = ' ' "
cGrpCus+= " 		AND X5_TABELA  = 'ZX' "
cGrpCus+= " 		AND X5_FILIAL  = '" + xFilial("SX5") + "'"	
cGrpCus+= " 		AND X5_CHAVE  = D1.D1_TIPO"
cGrpCus+= " 		AND ROWNUM = 1) AS DESCR"
cGrpCus+=" FROM " + retsqlname("SD1") + " D1" 
cGrpCus+=" WHERE D1_EMISSAO >= '" + (DToS(Date() - 90)) + "'"
cGrpCus+=" AND D_E_L_E_T_ = ' ' "
cGrpCus+=" AND D1_FILIAL = '"+xFilial("SD1")+"' "
cGrpCus+=" AND D1_TIPO >= '0'"
cGrpCus+=" GROUP BY D1_TIPO "
cGrpCus+=" UNION"
cGrpCus+=" SELECT DISTINCT D2_TIPO AS TIPO, "
cGrpCus+= "( SELECT X5_DESCRI "
cGrpCus+= "		FROM "+ RetSqlName("SX5") +" X5 "
cGrpCus+= " 		WHERE "
cGrpCus+= "     D_E_L_E_T_ = ' ' "
cGrpCus+= " 		AND X5_TABELA  = 'ZX' "
cGrpCus+= " 		AND X5_FILIAL  = '" + xFilial("SX5") + "'"	
cGrpCus+= " 		AND X5_CHAVE  = D2.D2_TIPO"
cGrpCus+= " 		AND ROWNUM = 1) AS DESCR"
cGrpCus+=" FROM " + retsqlname("SD2") + " D2" 
cGrpCus+=" WHERE D2_EMISSAO >= '" + (DToS(Date() - 90)) + "'"
cGrpCus+=" AND D_E_L_E_T_ = ' ' "
cGrpCus+=" AND D2_TIPO >= '0'"
cGrpCus+=" AND D2_FILIAL = '"+xFilial("SD2")+"' "
cGrpCus+=" GROUP BY D2_TIPO "

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf

cGrpCus := ChangeQuery(cGrpCus)
MPSysOpenQuery(cGrpCus,"TRB")

If TRB->(Eof())
	U_ITMsg("Nao ha registros para a data maior ou igual a " + (DToS(Date() - 90)),'Atenção!',,1)
EndIf

While TRB->(!Eof())
	MvParDef += AllTrim(TRB->TIPO)
	aAdd(aCat,AllTrim(TRB->DESCR))
	TRB->(DBSkip())
EndDo

/*
//==========================================================================
//Trativa abaixo para no caso de uma alteracao do campo trazer todos
//os dados que foram selecionados anteriormente.                    
//==========================================================================
*/
If Type("_cSeparador") <> "C"
   _cSeparador:=";"
EndIf 
If Len(AllTrim(&MvRet)) == 0
	
	MvPar:= PadR(AllTrim(StrTran(&MvRet,_cSeparador,"")),Len(aCat))
	&MvRet:= PadR(AllTrim(StrTran(&MvRet,_cSeparador,"")),Len(aCat))
	
Else
	
	MvPar:= AllTrim(StrTran(&MvRet,_cSeparador,"/"))
	
EndIf

/*
//==========================================================================
//Somente altera o conteudo caso o usuario clique no botao ok
//==========================================================================
*/

//Executa funcao que monta tela de opcoes
If f_Opcoes(@MvPar,cTitulo,aCat,MvParDef,12,49,.F.,nTam,nMaxSelect)
	
	//Tratamento para separar retorno com barra _cSeparador
	&MvRet := ""
	For i:=1 to Len(MvPar) step nTam
		If !(SubStr(MvPar,i,1) $ " |*")
			&MvRet  += SubStr(MvPar,i,nTam) + _cSeparador
		EndIf
	Next i
	
	//Trata para tirar o ultimo caracter
	&MvRet := SubStr(&MvRet,1,Len(&MvRet)-1)
	
EndIf

cRetF3:=&MvRet

If Select("TRB") >0
	TRB->(DBCloseArea())
EndIf
FWRestArea(_aarea)

Return(.T.)

Static Function GrvCposCapa()

ZL6->ZL6_FILIAL:= xFilial("ZL6")
ZL6->ZL6_TPCUS := M->ZL6_TPCUS
ZL6->ZL6_DTPCUS:= M->ZL6_DTPCUS
ZL6->ZL6_GRPCUS:= M->ZL6_GRPCUS
ZL6->ZL6_DGRCUS:= M->ZL6_DGRCUS
ZL6->ZL6_CODEVE:= M->ZL6_CODEVE 
ZL6->ZL6_DESEVE:= M->ZL6_DESEVE 
ZL6->ZL6_ORDGRU:= M->ZL6_ORDGRU
If ZL6->(FIELDPOS("ZL6_PRDRAT")) <> 0
   ZL6->ZL6_PRDRAT:= StrTran(M->ZL6_PRDRAT,_cSeparador,";")
EndIf

Return(.T.)
