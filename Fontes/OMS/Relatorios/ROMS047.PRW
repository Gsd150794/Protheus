/*
===============================================================================================================================
               ULTIMAS ATUALIZACOES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer 	  | 04/04/2017 | Foi criado relatório para apresentar as informações de desconto contratual. Chamados: 19135	        
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     	  | 24/05/2019 | Alterar relatório de descontos contratuais e incluir opção de filtro por codigo de rede. 
				  |			   | Chamado 29318. 
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  	  | 17/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346

====================================================================================================================================
Analista - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
===========================================================================================================================================================================================================================================================
Antonio  - Igor Melgaço - 29/09/24 - 29/09/24 -  47942  - Correção do error.log (cannot find fun ction ALTRIM) da Parte 1.
Antonio  - Igor Melgaço - 18/07/25 - 18/07/25 -  49904  - Inclusão de Valores de IPI e Analises de Totatilzadores
===============================================================================================================================
*/
//====================================================================================================
// Definicoes de Includes e Defines da Rotina.
//====================================================================================================
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: ROMS047
Autor-------------: Alex Wallauer
Data da Criacao---: 04/04/2017
===============================================================================================================================
Descrição---------: Relatorio dos descontos contratual
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS047()//U_ROMS047()

Private _cPerg := "ROMS047"
Private _aLista:= {}
Private _aTit  := {}

While .T.

   If !Pergunte( _cPerg , .T. )
      Exit
   EndIf

   lSair:=.F.
   Processa({|| lSair:=ROMS47Ger() } )

   If lSair
      Exit
   EndIf

   If !ROMS47Tela()
      Exit
   EndIf

EndDo

Return
/*
===============================================================================================================================
Programa----------: ROMS47Tela
Autor-------------: Alex Wallauer
Data da Criacao---: 04/04/2017
===============================================================================================================================
Descrição---------: Relatorio dos descontos contratual
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS47Tela()

Local cTit := "Filtros: Filiais ("+AllTrim(MV_PAR01)+")  /  Fornecedores de ("+MV_PAR02+"-"+MV_PAR03+") ate ("+MV_PAR04+"-"+MV_PAR05+")  /  Datas de "+DToC(MV_PAR06)+" ate "+DToC(MV_PAR07)+""

Local aSiz := NIL

Local lRet := U_ITListBox('Relatorio dos descontos contratual (ROMS047)',_aTit,_aLista,.T.,4,cTit,,aSiz)


Return !lRet

/*
===============================================================================================================================
Programa----------: ROMS042PR
Autor-------------: Alex Wallauer
Data da Criacao---: 04/04/2017
===============================================================================================================================
Descrição---------: Executa relatório
===============================================================================================================================
*/
Static Function ROMS47Ger()

Local _aSalveArea:=FWGetArea()
Local _cFiltro   := "% "
Local _PictValor :="@E 99,999,999,999.99"
Local L			:= 0
ProcRegua(3)
IncProc("Lendo dados...")
IncProc("Lendo dados...")

If !Empty(MV_PAR01)
   _cFiltro += " D2_FILIAL IN " + FormatIn(AllTrim(MV_PAR01),";") + " AND "
EndIf
_cFiltro += " ZAY.ZAY_FILIAL = '"+xFilial("ZAY")+"'"
_cFiltro += " AND ZAY.ZAY_TPOPER = 'V' "
_cFiltro += " AND D2_CLIENTE BETWEEN '"+ MV_PAR02 + "' AND '" + MV_PAR04 + "' "
_cFiltro += " AND D2_LOJA    BETWEEN '"+ MV_PAR03 + "' AND '" + MV_PAR05 + "' "
_cFiltro += " AND D2_EMISSAO BETWEEN '"+ DToS( MV_PAR06 ) +"' AND '"+ DToS( MV_PAR07 ) +"' "

If !Empty(MV_PAR08)
   _cFiltro += " AND A1_GRPVEN IN " + FormatIn(AllTrim(MV_PAR08),";") 
EndIf

_cFiltro += " %"

BeginSql alias "QRY1"
			
	SELECT D2_FILIAL, D2_DOC, D2_SERIE, D2_EMISSAO, D2_CLIENTE, D2_LOJA, D2_ITEM, D2_COD, D2_CF, D2_VALBRUT, D2_TOTAL, D2_ICMSRET, D2_PEDIDO,
	      (D2_I_VLRDC + D2_I_VLPAR) VLRDC, D2_I_PRCDC , D2_TES , D2_ITEMPV, D2_VALIPI //, A1_NREDUZ, B1_DESC, F2_I_DCUST
			      FROM %Table:SD2% SD2
			INNER JOIN %Table:ZAY% ZAY ON SD2.D2_CF = ZAY.ZAY_CF AND ZAY.%notDel%
         INNER JOIN %Table:SA1% SA1 ON SD2.D2_CLIENTE = SA1.A1_COD AND SD2.D2_LOJA = SA1.A1_LOJA AND SA1.%notDel%
			WHERE %exp:_cFiltro% AND SD2.%notDel%
	ORDER BY  D2_FILIAL, D2_DOC, D2_SERIE, D2_CLIENTE, D2_LOJA

EndSql

IncProc("Lendo dados...")

COUNT TO nTotal

ProcRegua(nTotal)

SA1->(DBSetOrder(1))
SF2->(DBSetOrder(1))
SC6->(DBSetOrder(1))

QRY1->(DBGoTop())

_cChaveNF  :=QRY1->D2_FILIAL+QRY1->D2_DOC+QRY1->D2_SERIE
_aLista    :={}
_nTotTitulo:=0
_nTotNFDesc:=0
_nContador :=0
cTotal     :=AllTrim(Str(nTotal))

While QRY1->(!Eof())
   
   _nContador++
   IncProc("Lendo NF: "+QRY1->D2_DOC+" - "+AllTrim(Str(_nContador))+" / "+cTotal)
   
   SA1->(DBSeek(xFilial()+QRY1->D2_CLIENTE+QRY1->D2_LOJA ))
   SF2->(DBSeek(QRY1->D2_FILIAL+QRY1->D2_DOC+QRY1->D2_SERIE ))
   _lTemPV:=SC6->(DBSeek(QRY1->D2_FILIAL+QRY1->D2_PEDIDO+QRY1->D2_ITEMPV))

   _cDescB1   := AllTrim(LEFT(Posicione("SB1" , 1 , xFilial("SB1") + QRY1->D2_COD , "B1_DESC"),35))
   _cDCust    := IIf(SF2->F2_I_DCUST == "S", "SIM", "NÃO")
   _cDCIPI    := IIf(SF2->F2_I_DCIPI == "S", "SIM", "NÃO")
   _nPerDPV   := 0
   _nVDCUSPV  := 0
   _nItemNFDes:= 0
   _nTotNFDesc+= QRY1->VLRDC

   If _lTemPV 

      _nVDCUSPV := _nPerDPV := SC6->C6_I_PDESC
	  If _nVDCUSPV # 0
		 If SF2->F2_I_DCUST = "S" // Posicione("ZAZ",1,xFilial("ZAZ")+SF2->F2_I_NRZAZ,"ZAZ_STBAS") = "S"  (posso usar o contrato da NF ou) // M->C5_I_NRZAZ (o contrato do PV)
		    _ntotal := QRY1->D2_TOTAL + QRY1->D2_ICMSRET
		 Else
		    _ntotal := QRY1->D2_TOTAL
		 EndIf			

       If SF2->F2_I_DCIPI = "S"
         _ntotal := _nTotal + QRY1->D2_VALIPI
       EndIf
       
	     _nItemNFDes := Round(_ntotal * ( _nVDCUSPV / 100 ),2)	//Valor do desconto integral
	  EndIf		

   ElseIf ( Posicione( "SF4" , 1 , QRY1->D2_FILIAL + QRY1->D2_TES , "F4_DUPLIC" ) == 'S' )

	  _aDados := U_veriContrato( QRY1->D2_CLIENTE , QRY1->D2_LOJA , QRY1->D2_COD ) //Verifica se existe calculo para o desconto
			
	  //Verifica o desconto integral                                                 |
	  If _aDados[1] > 0
		 //Se estiver aprovado pelo financeiro e com data de vigencia ativa             |
		 If _aDados[2] .And. _aDados[3]
			//Verifica se considera ST como base do desconto                               |
			If Posicione("ZAZ",1,xFilial("ZAZ")+_aDados[4],"ZAZ_STBAS") = "S"
			   _ntotal := QRY1->D2_TOTAL + QRY1->D2_ICMSRET
			Else
			   _ntotal := QRY1->D2_TOTAL
			EndIf			

			If Posicione("ZAZ",1,xFilial("ZAZ")+_aDados[4],"ZAZ_IPIBAS") = "S"
            _nTotal := _nTotal + QRY1->D2_VALIPI
         EndIf

         _nVDCUSPV     := _aDados[1]
			_nItemNFDes := Round(_ntotal * ( _aDados[1] / 100 ),2)	//Valor do desconto integral
			_nItemNFDes += Round(_ntotal * ( _aDados[5] / 100 ),2)	//Valor do desconto parcial

		 EndIf			
	  EndIf			
   
   EndIf

                                                                                                                                                                                                //"PV %"    ,"NF %"             ,"PV Desconto"       ,"NF Desconto"     ,"DP Desconto"     ,"DIF PV / NF" ,"EXCLUIR COLUNA" ,"DIF NF / DP"
   _cDifItemPVNF:= TRANSF(QRY1->VLRDC-_nItemNFDes,_PictValor)                                   																									//%Desc PV      %Desc NF            ,"Vlr Desc. Item PV","Vlr Desc. Item NF","Vlr Desc. Titulo","Vlr Dif Item","Vlr Desconto NF","Vlr Dif Titulo"
   _lIgual:= (Round(QRY1->VLRDC-_nItemNFDes,2) = 0)                                                                                                                                                      //"Vlr Desc. Item PV","% Desc NF","Vlr Desc. Item NF","Vlr Dif Item","Vlr Desconto NF","Vlr Desc. Titulo","Vlr Dif Titulo","Utiliza ST?"}
                                                                                                                                                                                                   //_nItemNFDes        ,D2_I_PRCDC ,VLRDC              ,_cDifItemPVNF ,0                ,0                 ,0               ,_cDCust      } ))
               _aTit := {" "    ,"Filial" ,"Documento","Emissão"             ,"Cliente" ,"Loja" ,"Nome"        ,"Produto","Descrição","Valor Mercadoria NF","ICMS Ret","Utiliza ST?","Uti. IPI?","Vlr. Bruto NF","Val.IPI", "Pedido" ,"PV %"   ,"NF %"    ,"PV Desconto","NF Desconto","DP Desconto","DIF PV / NF" ,"DIF NF / DP"}
   QRY1->( aAdd(_aLista,{_lIgual,D2_FILIAL,D2_DOC     ,DToC(SToD(D2_EMISSAO)),D2_CLIENTE,D2_LOJA,SA1->A1_NREDUZ,D2_COD   ,_cDescB1   ,D2_TOTAL             ,D2_ICMSRET,_cDCust      ,_cDCIPI    ,D2_VALBRUT     ,D2_VALIPI, D2_PEDIDO,_nVDCUSPV,D2_I_PRCDC,_nItemNFDes  ,QRY1->VLRDC  ,0            ,_cDifItemPVNF ,0            } ))
                        // 1    ,2        ,3          ,4                     ,5         ,6      ,7             ,8        ,9          ,10                   ,11        ,12           ,13         ,14             ,15       ,16        ,17       ,18        ,19           ,20           ,21           ,22            ,23                         

   For L := 1 TO Len(_aLista[Len(_aLista)])
       If ValType(_aLista[Len(_aLista),L]) = "N"
          _aLista[Len(_aLista),L] := TRANSF(_aLista[Len(_aLista),L], _PictValor )
       EndIf
   Next

   QRY1->(DBSkip())

   If _cChaveNF # QRY1->D2_FILIAL+QRY1->D2_DOC+QRY1->D2_SERIE

      _nTotTitulo:= ROMS47Tit(SF2->F2_FILIAL + SF2->F2_CLIENTE + SF2->F2_LOJA + "DCT" + SF2->F2_DOC,SF2->F2_DOC)      

      _nPos:=21
    //_aLista[Len(_aLista),_nPos+0]:=TRANSF(_nTotNFDesc, _PictValor )          //"Vlr Desconto NF"
      _aLista[Len(_aLista),_nPos+0]:=TRANSF(_nTotTitulo, _PictValor )          //"Vlr Desc. Titulo"//19
      _aLista[Len(_aLista),_nPos+2]:=TRANSF(_nTotNFDesc-_nTotTitulo,_PictValor)//"Vlr Dif Titulo"  //21

      _aLista[Len(_aLista),01]:= (_aLista[Len(_aLista),01] .And. (Round(_nTotNFDesc-_nTotTitulo,2) = 0))

      _cChaveNF  :=QRY1->D2_FILIAL+QRY1->D2_DOC+QRY1->D2_SERIE
      _nTotNFDesc:=0
      
   EndIf

EndDo

QRY1->(DBCloseArea())

FWRestArea(_aSalveArea)

Return !Len(_aLista) > 0


/*
===============================================================================================================================
Programa----------: ROMS47Tit()
Autor-------------: Alex Wallauer
Data da Criacao---: 04/04/2017
===============================================================================================================================
Descrição---------: Função para ler os titulos
===============================================================================================================================
*/
Static Function ROMS47Tit(cChaveSE1,_cDoc)

Local _nE1NccV	:= 0
                 
SE1->( DBSetOrder(2) ) //E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
If SE1->( DBSeek( cChaveSE1 ) )

   While SE1->( !Eof() ) .And. SE1->E1_NUM = _cDoc

	   If SE1->E1_TIPO = "NCC"
		
	      _nE1NccV += SE1->E1_VALOR
	    	
	   EndIf
		
	   SE1->( DBSkip() )
	
	EndDo
	
EndIf

Return _nE1NccV
