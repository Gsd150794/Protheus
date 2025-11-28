/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |02/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Alex Wallauer |20/03/2020| Chamado 32334. Mensagem na geração do recibo de entrega do EPI X geração da SA.
Jonathan      |16/07/2020| Chamado 33416. Ajuste da impressão do recibo de entrega.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "MDTR805.ch"

/*
===============================================================================================================================
Programa----------: RMDT001
Autor-------------: Josué Danich Prestes
Data da Criacao---: 01/09/2015
Descrição---------: Recibo de entrega de EPI copiado e ajustado do fonte padrão MDTR805
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RMDT001

//=======================================================================
// Define Variaveis                                             
//=======================================================================
Local _cwnrel   := "MDTR805"
Local _aArea := FWGetArea()
Local _cDesc1  := STR0001 //"Relatorio de Comprovante de Entrega de EPI.                                     "
Local _cDesc2  := STR0002 //"Conforme parametros o usuario pode selecionar os funcionarios, periodo desejado "
Local _cDesc3  := STR0003 //"e indicar se deseja imprimir apenas epi's nao impressos ou para todos.          "
Local _cString := "TNF"
Local _cQry  , D
Private nomeprog 	:= "MDTR805"
Private tamanho  	:= "M"
Private  aReturn  	:= { STR0004, 1,STR0005, 2, 2, 1, "",1 } //"Zebrado"###"Administracao"
Private titulo   	:= STR0006 //"Comprovante de Entrega de EPI"
Private _ntipo    	:= 0
Private nLastKey 	:= 0
Private cPerg    	:= "MDT805    "
Private cabec1	 	:= " "
Private cabec2   	:= " "
Private nSizeSI3, nSizeSRJ
Private cFuncMat  	:= " "
Private _cULIT		:= '01'
Private _cUlSC		:= CA105NUM

_l655CTR := .F.
//filtra só entregas da filial sem recibo impresso
_cQry := "SELECT TNF.R_E_C_N_O_ AS NRRECNO FROM " + RetSqlName("TNF") + " TNF " 
_cQry += " WHERE TNF.D_E_L_E_T_ = ' ' AND TNF_FILIAL = '" + xFilial("TNF") + "' "
_cQry += " AND TNF_MAT = '" +M->RA_MAT+ "' AND TNF_DTRECI = '        ' "

If Select("QRYTNF") > 0
	QRYTNF->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "QRYTNF" , .T. , .F. )

QRYTNF->(DBGoTop())

_aDados:={} 
lTemErro:=.F.
SCP->(DBSetOrder(1))
While ! QRYTNF->(Eof())  
   
   TNF->(DBGoTo(QRYTNF->NRRECNO))
   aItem:={}
   aAdd(aItem,.T.)
   cMens:="SA Gerada com sucesso"
   If Empty(TNF->TNF_NUMSA)

      aAdd(aItem,_cUlSC+"*")
      If !SCP->(DBSeek(cFilAnt+_cUlSC))
         aItem[1]:=.F.    
         lTemErro:=.T.
         cMens:="Não gerou a SA corretamente"
      EndIf

   Else

      aAdd(aItem,TNF->TNF_NUMSA)
      If !SCP->(DBSeek(cFilAnt+TNF->TNF_NUMSA))
         aItem[1]:=.F.
         lTemErro:=.T.
         cMens:="Não gerou a SA corretamente"
      EndIf

   EndIf
   aAdd(aItem,TNF->TNF_MAT+"-"+NgSeek('SRA',TNF->TNF_MAT,1,'SRA->RA_NOME'))
// aAdd(aItem,SRA->RA_RG)
// aAdd(aItem,SRA->RA_NASC)
// aAdd(aItem,SRA->RA_ADMISSA)
// aAdd(aItem,AllTrim( Str( YEAR(DATE())-YEAR(SRA->RA_ADMISSA),3 ) )  )
   aAdd(aItem,SRA->RA_CC+ "-"+NgSeek('SI3',SRA->RA_CC,1,'SI3->I3_DESC') )
// aAdd(aItem,TNF->TNF_CODFUN+"-"+AllTrim (NgSeek('SRJ',TNF->TNF_CODFUN,1,'SRJ->RJ_DESC')) )      
   aAdd(aItem,AllTrim(TNF->TNF_CODEPI)+"-"+NgSeek('SB1',TNF->TNF_CODEPI,1,'SB1->B1_DESC'))
   aAdd(aItem,DToC(TNF->TNF_DTENTR))			 
   aAdd(aItem,TNF->TNF_HRENTR)
   aAdd(aItem,TNF->TNF_QTDENT) 
   aAdd(aItem,If(TNF->TNF_INDDEV = "1","SIM","NAO"))
   aAdd(aItem,cMens)
   aAdd(aItem,QRYTNF->NRRECNO)
   
   aAdd(_aDados,aItem)
   QRYTNF->(DBSkip()) 

EndDo

While Len(_aDados) > 0 .And. lTemErro
   _aTit:={}
   _aSiz:={}
   aAdd(_aTit,' ') 
   aAdd(_aSiz,10)
   aAdd(_aTit,'S.A.') 
   aAdd(_aSiz,10)
   aAdd(_aTit,'FUNCIONARIO') 
   aAdd(_aSiz,120)
/* aAdd(_aTit,'RG')
   aAdd(_aSiz,35)
   aAdd(_aTit,'NASC')
   aAdd(_aSiz,35)
   aAdd(_aTit,'ADMIS')
   aAdd(_aSiz,30)
   aAdd(_aTit,'IDADE')
   aAdd(_aSiz,20)*/
   aAdd(_aTit,'CENTRO DE CUSTO')
   aAdd(_aSiz,100)
// aAdd(_aTit,'FUNCAO')
// aAdd(_aSiz,100)
   aAdd(_aTit,'EPI')
   aAdd(_aSiz,120)
   aAdd(_aTit,'DT ENT')
   aAdd(_aSiz,20)
   aAdd(_aTit,'HORA')
   aAdd(_aSiz,20)
   aAdd(_aTit,'QTDE')
   aAdd(_aSiz,20)
   aAdd(_aTit,'DEVOLUCAO')
   aAdd(_aSiz,20)
   aAdd(_aTit,'RESULTADO')
   aAdd(_aSiz,20)

   _cTitulo:="EPIs SEM SA"

   _cMsgTop:="ATENÇÃO: Não foi possível gerar a Solicitação ao Armazém, desta forma os EPIs entregues serão EXCLUIDOS do Funcionário. SOLUÇÃO: Refaça o processo de entrega de EPIs ao funcionário." 
   
   LDEL:=.F.

   bOk    :={|oDlg| If(U_ITMsg("Confirma EXCLUIR os EPIs ENTREGUES ?"         ,'Atenção!',,2,2,2) , (LDEL:=.T. ,oDlg:End() ), )    }
   bCancel:={|oDlg| If(U_ITMsg("Confirma SAIR SEM excluir os EPIs ENTREGUES ?",'Atenção!',,3,2,2) , (LDEL:=.F. ,oDlg:End() ), )    }

   //                           , _aCols  ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons )
      U_ITListBox(_cTitulo,_aTit,_aDados  , .T.    , 4    ,_cMsgTop,          ,_aSiz   ,         , bOk ,bCancel, )
                                                                                                  
   If LDEL
      nConta:=0
      For D := 1 TO Len(_aDados)  
         If !_aDados[ D , 1 ]
            TNF->(DBGoTo( _aDados[ D , Len( _aDados[D] ) ] ))
            TNF->(RecLock("TNF",.F.))
            TNF->(DBDELETE())
            nConta++
         EndIf
      Next   
      
      U_ITMsg(AllTrim(Str(nConta))+" REGISTROS APAGADOS COM SUCESSO",'Atenção!',,2)
      
      If Len(_aDados) <> nConta
         Exit
      EndIf

   EndIf

   Return .F.

EndDo

nSizeSI3 := If((TamSX3("I3_CUSTO")[1]) < 1,9,(TamSX3("I3_CUSTO")[1]))
nSizeSRJ := If((TamSX3("RJ_FUNCAO")[1]) < 1,4,(TamSX3("RJ_FUNCAO")[1])) 



//=======================================================================
// Verifica as perguntas selecionadas                           
//=======================================================================

Pergunte(cPerg,.F.)
MV_PAR01 := '      '
MV_PAR02 := 'ZZZZZZ'
MV_PAR03 := SToD('19900101')
MV_PAR04 := SToD('20301231')
MV_PAR05 := 1
MV_PAR06 := '     '
MV_PAR07 := 1
MV_PAR08 := 1
MV_PAR09 := '      '
MV_PAR10 := 'ZZZZZZ'
MV_PAR11 := 2
MV_PAR12 := 1
MV_PAR13 := SToD('19900101')
MV_PAR14 := SToD('20301231')
MV_PAR15 := xFilial("TNF")
MV_PAR16 := xFilial("TNF")
MV_PAR17 := 1
MV_PAR18 := 2

//=======================================================================
// Variaveis utilizadas para parametros                                     
// MV_PAR01             // De Funcionario                                   
// MV_PAR02             // Ate Funcionario                                  
// MV_PAR03             // De Data Entrega                                  
// MV_PAR04             // Ate Data Entrega                                 
// MV_PAR05             // So nao Impresos / Todos / Ultima retirada        
// MV_PAR06             // Termo de Responsabilidade                        
// MV_PAR07             // Duas vias                                        
// MV_PAR08             // Ordenar por                                      
// MV_PAR09             // De Centro de Custo                               
// MV_PAR10             // Ate Centro de Custo                              
// MV_PAR11             // Considerar funcionarios demitidos                
//                            1 - Sim                                       
//                            2 - Nao                                       
//=======================================================================


//=======================================================================
// Envia controle para a funcao SETPRINT                        
//=======================================================================
_cwnrel:="RMDT001"

//            cAlias,cProgram [ cPergunte ] [ cTitle ] [ cDesc1 ] [ cDesc2 ] [ cDesc3 ] [ lDic ] [ aOrd ] [ lCompres ] [ cSize ] [ uParm12 ] [ lFilter ] [ lCrystal ] [ cNameDrv ] [ uParm16 ] [ lServer ] [ cPortPrint ]  
// 
_cwnrel := SetPrint(_cString,_cwnrel ,              ,titulo    ,_cDesc1   ,_cDesc2  ,_cDesc3    ,.F.     ,""       ,           ,          ,           ,           ,             ,         ,          ,   .F.       ,             )

//_cwnrel:=SetPrint(_cString,_cwnrel,,titulo,_cDesc1,_cDesc2,_cDesc3,.F.,"")

If nLastKey == 27
If Select("QRYTNF") > 0
	QRYTNF->( DBCloseArea() )
EndIf
    Set Filter to
    Return

EndIf

SetDefault(aReturn,_cString)

If nLastKey == 27
If Select("QRYTNF") > 0
	QRYTNF->( DBCloseArea() )
EndIf
   Set Filter to
   Return

EndIf

RptStatus({|lEnd| RMDT001R(@lEnd,_cwnrel,titulo,tamanho)},titulo)

If Select("QRYTNF") > 0
	QRYTNF->( DBCloseArea() )
EndIf

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: RMDT001R
Autor-------------: Josué Danich Prestes
Data da Criacao---: 01/09/2015
Descrição---------: Chamada do Relat¢rio 
Parametros--------: 	lEnd - controle de sucesso do relatório
						_cwnrel - objeto de impressão
						titulo - Título do relatório
						tamanho - se é condensado ou não
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RMDT001R(lEnd,_cwnrel,titulo,tamanho)

//=======================================================================
// Define Variaveis                                             
//=======================================================================
Local _cCC := ""

//=======================================================================
// Variaveis para controle do cursor de progressao do relatorio 
//=======================================================================
Local _nTotRegs := 0

//=======================================================================
// Variaveis locais exclusivas deste programa                   
//=======================================================================
Local _aDBF := {}

//=======================================================================
// Contadores de linha e pagina                                 
//=======================================================================
Private li := 80 ,m_pag := 1
Private lCPONumcap := .T.,lCPODtVenc := .T.

If TNF->(FieldPos("TNF_NUMCAP")) <= 0

	lCPONumcap := .F.

EndIf

aAdd(_aDBF,{"FUNCI"  , "C", 06,0})           
aAdd(_aDBF,{"NOME"   , "C", 40,0})           
aAdd(_aDBF,{"RG"     , "C", 15,0})           
aAdd(_aDBF,{"NASC"   , "D", 08,0})           
aAdd(_aDBF,{"ADMIS"  , "D", 08,0})           
aAdd(_aDBF,{"IDADE"  , "C", 03,0})           
aAdd(_aDBF,{"CC"     , "C", nSizeSI3,0})
aAdd(_aDBF,{"DESCC"  , "C", 60,0})  
aAdd(_aDBF,{"FUNCAO" , "C", nSizeSRJ,0})
aAdd(_aDBF,{"DESCFUN", "C", 20,0})   
aAdd(_aDBF,{"CODEPI" , "C", 15,0}) 
aAdd(_aDBF,{"DESEPI" , "C", 40,0}) 
aAdd(_aDBF,{"DTENT"  , "D", 08,0}) 
aAdd(_aDBF,{"HRENT"  , "C", 05,0}) 
aAdd(_aDBF,{"QTDE"   , "N", 06,2}) 
aAdd(_aDBF,{"DEV"    , "C", 01,0}) 
aAdd(_aDBF,{"NUMCAP" , "C", 12,0}) 
aAdd(_aDBF,{"NUMCRI" , "C", 12,0})
aAdd(_aDBF,{"NUMCRF" , "C", 12,0})
aAdd(_aDBF,{"DTDEVO" , "D", 08,0})
aAdd(_aDBF,{"NUMSA"  , "C", 12,0})
aAdd(_aDBF,{"ITEMSA" , "C", 12,0}) 
aAdd(_aDBF,{"NRRECNO", "N", 10,0})

If Select("TRB") <> 0
	TRB->( DBCloseArea() )
EndIf

_otemp := FWTemporaryTable():New( "TRB", _aDBF )

If MV_PAR12 == 1  //Cod EPI

	_otemp:AddIndex( "01", {"FUNCI","CODEPI","DTENT"} )
	_otemp:AddIndex( "02", {"NOME","CODEPI","DTENT"} )
	_otemp:AddIndex( "03", {"CC","FUNCI","CODEPI","DTENT"} )
	_otemp:AddIndex( "04", {"DESCC","FUNCI","CODEPI","DTENT"} )

Else  //Nome EPI

	_otemp:AddIndex( "01", {"FUNCI","DESEPI","DTENT"} )
	_otemp:AddIndex( "02", {"NOME","DESEPI","DTENT"} )
	_otemp:AddIndex( "03", {"CC","FUNCI","DESEPI","DTENT"} )
	_otemp:AddIndex( "04", {"DESCC","FUNCI","DESEPI","DTENT"} )

EndIf

_otemp:Create()

//=======================================================================
// Verifica se deve comprimir ou nao                            
//=======================================================================
_ntipo  := IIf(aReturn[4]==1,15,18)


Count to _nTotRegs

SetRegua(_nTotRegs)

QRYTNF->(DBGoTop())

//=======================================================================
// Efeuta a leitura dos dados da tabela TNF, com base no resultado da
// query para ler os  EPI's Entregues aos Funcionarios.
//=======================================================================
While ! QRYTNF->(Eof())  
   
   TNF->(DBGoTo(QRYTNF->NRRECNO))
	
	IncRegua()
	
	DBSelectArea("SRA")
	SRA->(DBSetOrder(1))
	SRA->(DBSeek(xFilial("SRA")+TNF->TNF_MAT))
	
	_cCC := SRA->RA_CC
 	cFuncMat := TNF->TNF_MAT
 	
   	DBSelectArea("TNF")       
	RecLock("TNF",.F.)
	TNF->TNF_DTRECI := Date()
	MSUnLock("TNF")
	
  	U_RMDT001G()
  	 
	QRYTNF->(DBSkip())	
	
EndDo

If Select("QRYTNF") > 0 
   QRYTNF->( DBCloseArea() )
EndIf

u_RMDT001I() 

DBSelectArea("TRB")
USE
      
//=======================================================================
// Devolve a condicao original do arquivo principal             
//=======================================================================
RetIndex("TNF")

Set Filter To

Set device to Screen

If aReturn[5] = 1

	Set Printer To
 	dbCommitAll()
  	OurSpool(_cwnrel)

EndIf

MS_FLUSH()
DBSelectArea("TNF")
DBSetOrder(2)

Return

/*
===============================================================================================================================
Programa----------: RMDT001S
Autor-------------: Josué Danich Prestes
Data da Criacao---: 01/09/2015
Descrição---------: Incrementa Linha e Controla Salto de Pagina
Parametros--------: 	Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RMDT001S()
  
li++

If li > 58   
 
     Cabec(titulo,cabec1,cabec2,nomeprog,tamanho,_ntipo)

EndIf

Return
/*
          1         2         3         4         5         6         7         8         9         0         1         2         3
0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012
=====================================================================================================================================
XXXXXXXXXXXXX                                      COMPROVANTE DE ENTREGA DE EPI'S                                                 
SIGA/RMDT001                                    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx                Emissao: 99/99/99   hh:mm    
=====================================================================================================================================
Funcionario.....: xxxxxx - xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx                         RG.: xxx.xxx.xxx			        		
Centro de Custo.: xxxxxxxxx - xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx						 		                                    
Funcao..........: xxxx  -  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx   					                                     		
Nascimento......: xx/xx/xx                                                               Admissao.: xx/xx/xx     Idade.: xx  		
=====================================================================================================================================
EPI              Nome do EPI                        Dt. Entr  Hora     Qtde  Dev. Dt. Devo  Num. CA 	                            
  Num. CRF      Num. CRI                           													                            
xxxxxxxxxxxxxxx  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  xx/xx/xx  xx:xx  xxx,xx  xxx  xx/xx/xx  xxxxxxxxxxxx  Ass.: _________________  
  xxxxxxxxxxxx  xxxxxxxxxxxx                                                                                                       
xxxxxxxxxxxxxxx  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  xx/xx/xx  xx:xx  xxx,xx  xxx  xx/xx/xx  xxxxxxxxxxxx  Ass.: _________________  
xxxxxxxxxxxxxxx  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  xx/xx/xx  xx:xx  xxx,xx  xxx  xx/xx/xx  xxxxxxxxxxxx  Ass.: _________________  
                                                                               													
=====================================================================================================================================
       Data : ___/___/___                                                           							              	    
                                                                               													
|       Assinatura: _______________________                                   Resp Empr: _______________________                     
                                                                               													
=====================================================================================================================================
*/             

/*
===============================================================================================================================
Programa----------: RMDT001I
Autor-------------: Josué Danich Prestes
Data da Criacao---: 01/09/2015
Descrição---------: Impressão do Relatório
Parametros--------: 	Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RMDT001I()

Local linhaCorrente
Local _lPrimvez := .T.
Local _cDt := ""

DBSelectArea("TRB")
If MV_PAR08 == 1  //Matricula
	DBSetOrder(1)
ElseIf MV_PAR08 == 2  //Nome Funcionario
	DBSetOrder(2)
ElseIf MV_PAR08 == 3  //Cod. C. Custo
	DBSetOrder(3)
ElseIf MV_PAR08 == 4  //Nome C. Custo
	DBSetOrder(4)	
EndIf

DBGoTop()
While !Eof()

	CFUNC := TRB->FUNCI
	nVolta := 0
	RMDT001S()
	@ li,000 PSay " "+Replicate("_",131)
	RMDT001S()
	@ li,000 PSay "|"
	@ li,001 Psay STR0027+ SubStr(SM0->M0_NOMECOM,1,60) //"Empresa...:"
	@ li,083 Psay "CGC..:"+ SM0->M0_CGC
	@ li,132 PSay "|"
	RMDT001S()
	
	@ li,000 PSay "|"
	@ li,001 Psay STR0028+ SM0->M0_ENDENT //"Endereco..:"
	@ li,083 Psay STR0029 + SM0->M0_CIDCOB //"Cidade..:"
	@ li,118 Psay STR0030 +":"+ SM0->M0_ESTCOB //"Estado.."
	@ li,132 PSay "|"
	RMDT001S()
	@ li,000 PSay "|"
	@ li,001 PSay Replicate("_",131)
	@ li,132 PSay "|"
	
	RMDT001S()
	@ li,000 PSay STR0010 //"|Funcionario.....:"
	@ li,019 PSay CFUNC PICTURE "@!"
	@ li,026 PSAY " - " + TRB->NOME
	@ li,090 PSay STR0011 //"RG.:"
	@ li,095 PSay TRB->RG PICTURE "@!"
	@ li,132 PSay "|"
	
	RMDT001S()
	@ li,000 PSay STR0012 //"|Centro de Custo.:"

	@ li,019 PSay AllTrim(TRB->CC) +" - "+ AllTrim(TRB->DESCC)
	@ li,132 PSay "|"
	
	RMDT001S()                                 
	@ li,000 PSay STR0013 //"|Funcao..........:"
	@ li,019 PSay AllTrim(TRB->FUNCAO) +" - "+ AllTrim(TRB->DESCFUN) PICTURE "@!"
	@ li,132 PSay "|"
	
	RMDT001S()
	@ li,000 PSay STR0014 //"|Nascimento......:"
	@ li,019 PSay TRB->NASC PICTURE '99/99/99'
	@ li,090 PSay STR0015 //"Admissao.:"
	@ li,101 PSay TRB->ADMIS PICTURE '99/99/99'
	@ li,114 PSay STR0016 //"Idade.:"
	@ li,121 PSay TRB->IDADE +" "+ STR0039 //"anos"
	@ li,132 PSay "|"
	
	llinha := .F. 
	lFirst := .T.
	
	RMDT001S()
	@ li,000 PSay "|"
	@ li,001 PSay Replicate("_",131)
	@ li,132 PSay "|"
	RMDT001S()
	@ li,000 Psay "|"
	@ li,001 PSay STR0017     //"EPI"
	@ li,017 PSay STR0018     //"Nome do EPI"
	@ li,053 PSay STR0019     //"Dt. Entr"
	@ li,063 PSay STR0040     //"Hora"
	@ li,072 PSay STR0025     //"Qtde"
	@ li,078 PSay STR0020     //"Dev."

	If TNF->(FieldPos("TNF_DTDEVO")) > 0

		@ li,083 PSay STR0042 //"Dt. Devo"

	EndIf	

	@ li,093 PSay STR0026	  //"Num C.A."
	@ li,132 Psay "|"    
	RMDT001S()
	@ li,000 Psay "|"
	DBSelectArea("TN3")

	If TN3->(FieldPos("TN3_NUMCRF")) > 0

		@ li,002 PSay STR0033  //"Num. CRF"
		lLinha := .T.

	EndIf

	If TN3->(FieldPos("TN3_NUMCRI")) > 0

		@ li,016 PSay STR0034  //"Num. CRI"
		lLinha := .T.

	EndIf
	
	
	@ li,030 PSay "Num. SA"
	@ li,044 PSay "Item"


	DBSelectArea('TRB')

	While !Eof() .And. TRB->FUNCI == CFUNC

			If lLinha .And. lFirst

				@ li,132 Psay "|"
				RMDT001S()
				@ li,000 PSay "|"

			EndIf

			If !lFirst

				RMDT001S()
				@ li,000 PSay "|"

			EndIf	

			lFirst := .F.
			_cDt := StrZero(Day(TRB->DTENT),2)+"/"+StrZero(Month(TRB->DTENT),2)+"/"+SubStr(Str(Year(TRB->DTENT),4),3,2)
			
			@ li,001 PSAY TRB->CODEPI
			@ li,017 PSay SubStr(AllTrim(TRB->DESEPI),1,32) PICTURE "@!"
			@ li,053 PSay _cDt PICTURE "99/99/99"
			@ li,063 PSay TRB->HRENT PICTURE "99:99"
			@ li,070 PSay TRB->QTDE  PICTURE "@E 999.99"

			If TRB->DEV = "1"

				@ li,078 PSAY STR0021 //"SIM"

			Else

				@ li,078 PSAY STR0022  //"NAO"

			EndIf

			_cDt := StrZero(Day(TRB->DTDEVO),2)+"/"+StrZero(Month(TRB->DTDEVO),2)+"/"+SubStr(Str(Year(TRB->DTDEVO),4),3,2)

			If TNF->(FieldPos("TNF_DTDEVO")) > 0

				@ li,083 PSay _cDt PICTURE "99/99/99"

			EndIf			

			If !Empty(TRB->NUMCAP)

				@ li,093 PSay AllTrim(SubStr(TRB->NUMCAP,1,12))    

			EndIf

			If llinha        

				@ li,132 Psay "|"
				RMDT001S()
				@ li,000 Psay "|"

			EndIf	

			DBSelectArea("TN3")

			If TN3->(FieldPos("TN3_NUMCRF") > 0)

				@ li,002 PSay TRB->NUMCRF

			EndIf

			If TN3->(FieldPos("TN3_NUMCRI") > 0)

				@ li,016 PSay TRB->NUMCRI

			EndIf
			
			//@ li,030 PSay TRB->NUMSA  
			//@ li,044 PSay TRB->ITEMSA 
			
			_nRegAtu := TNF->(Recno()) 	 
			TNF->(DBGoTo(TRB->NRRECNO)) 
			   
            @ li,030 PSay TNF->TNF_NUMSA   
			@ li,044 PSay TNF->TNF_ITEMSA			
			
			TNF->(DBGoTo(_nRegAtu)) 

			@ li,107 PSay "Ass.: _________________"
			@ li,132 PSay "|"
			nVolta++
			DBSelectArea("TRB")
			DBSkip()

	EndDo

	DBSkip(-1)
	    	
	//termo
	DBSelectArea("TMZ")
	DBSetOrder(01)

	If DBSeek(xFilial("TMZ")+MV_PAR06)

		RMDT001S()
		@ li,000 PSay "|"
		@ li,001 PSay Replicate("_",131)
		@ li,132 PSay "|"
		RMDT001S()
		@ li,000 PSay "|"
		@ li,048 PSay STR0041 //"TERMO DE RESPONSABILIDADE"
		@ li,132 PSay "|"
		RMDT001S()
		@ li,000 PSay "|"
		lPrimeiro := .T.
		
		nLinhasMemo := MLCOUNT(TMZ->TMZ_DESCRI,130)

		For linhaCorrente := 1 to nLinhasMemo

			If lPrimeiro

				If !Empty((MemoLine(TMZ->TMZ_DESCRI,56,linhaCorrente)))

					@ li,001 PSAY (MemoLine(TMZ->TMZ_DESCRI,130,linhaCorrente))
					@ li,132 PSay "|"
					lPrimeiro := .F.

				Else

					Exit

				EndIf

			Else

				@ li,000 PSay "|"
				@ li,001 PSAY (MemoLine(TMZ->TMZ_DESCRI,130,linhaCorrente))
				@ li,132 PSay "|"

			EndIf

			RMDT001S()

		Next

		If !lPrimeiro

			@ li,000 PSay "|"

		EndIf

		@ li,132 PSay "|"

	EndIf

	// fim do termo
	
	RMDT001S()
	@ li,000 PSay "|"
	@ li,001 PSay Replicate("_",131)
	@ li,132 PSay "|"
	RMDT001S()
	@ li,000 PSay "|"
	@ li,132 PSay "|"
	RMDT001S()
	@ li,000 PSay STR0036 //"|       Data : ____/____/____"
	@ li,132 PSay "|"
	RMDT001S()
	@ li,000 PSay "|"
	@ li,132 PSay "|"
	RMDT001S()
	@ li,000 PSay STR0037 //"|       Assinatura: _______________________                                   Resp Empr: _______________________"
	@ li,132 Psay "|"
	RMDT001S()
	@ li,000 Psay "|"
	@ li,132 Psay "|"
	RMDT001S()
	@ li,000 PSay "|"
	@ li,001 PSay Replicate("_",131)
	@ li,132 PSay "|"        
	li := 80

	If MV_PAR07 == 2 .And. _lPrimvez

		DBSelectArea("TRB")
		DBSkip(-(nVolta-1))
		_lPrimvez := .F.

	Else

		DBSelectArea("TRB")     
		DBSkip()
		_lPrimvez := .T.

	EndIf
	
EndDo

Return

/*
===============================================================================================================================
Programa----------: RMDT001G
Autor-------------: Josué Danich Prestes
Data da Criacao---: 01/09/2015
Descrição---------: Armazena informacoes de um recibo para impressao.
Parametros--------: 	Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RMDT001G()

DBSelectArea("TN3")
TN3->(DBSetOrder(1))
TN3->(DBSeek(xFilial("TN3")+TNF->TNF_FORNEC+TNF->TNF_LOJA+TNF->TNF_CODEPI+TNF->TNF_NUMCAP))

DBSelectArea("TRB")
TRB->(DbAppend())
TRB->FUNCI    := cFuncMat
TRB->NOME     := SubStr(NgSeek('SRA',cFuncMat,1,'SRA->RA_NOME'),1,40)
TRB->RG       := NgSeek('SRA',cFuncMat,1,'SRA->RA_RG')
TRB->NASC     := NgSeek('SRA',cFuncMat,1,'SRA->RA_NASC')
TRB->ADMIS    := NgSeek('SRA',cFuncMat,1,'SRA->RA_ADMISSA')
TRB->IDADE    := AllTrim( Str( YEAR(DATE())-YEAR(TRB->NASC),3 ) )
TRB->CC       := NgSeek('SRA',cFuncMat,1,'SRA->RA_CC')
TRB->DESCC    := NgSeek('SI3',TRB->CC,1,'SI3->I3_DESC')
TRB->FUNCAO   := TNF->TNF_CODFUN
TRB->DESCFUN  := AllTrim (NgSeek('SRJ',TRB->FUNCAO,1,'SRJ->RJ_DESC'))       
TRB->CODEPI   := TNF->TNF_CODEPI
TRB->DESEPI   := NgSeek('SB1',TNF->TNF_CODEPI,1,'SB1->B1_DESC')
TRB->DTENT    := TNF->TNF_DTENTR			 
TRB->HRENT    := TNF->TNF_HRENTR
TRB->QTDE     := TNF->TNF_QTDENT
TRB->DEV      := TNF->TNF_INDDEV
TRB->NUMCAP   := If(lCPONumcap,TNF->TNF_NUMCAP,TN3->TN3_NUMCAP)
TRB->NRRECNO  := TNF->(Recno())

If  Empty(TNF->TNF_NUMSA)
	//grava SCP gravada nessa liberação e controla item da SCP
	TRB->NUMSA 	:= _cUlSC+"*"
	TRB->ITEMSA	:= StrZero(Val(_cULIT),2)
	_cUlit := StrZero(Val(_cULIT)+1,2)
Else
	//Grava SCP já salva anteriormente
	TRB->NUMSA		:= TNF->TNF_NUMSA
	TRB->ITEMSA	:= StrZero(Val(_cULIT),2)
	_cUlit := StrZero(Val(_cULIT)+1,2)
	_cUlSC := TNF->TNF_NUMSA
EndIf

If TN3->(FieldPos("TN3_NUMCRI")) > 0 
	TRB->NUMCRI    := TN3->TN3_NUMCRI
EndIf

If TN3->(FieldPos("TN3_NUMCRF")) > 0 
	TRB->NUMCRF    := TN3->TN3_NUMCRF
EndIf

If TNF->(FieldPos("TNF_DTDEVO")) > 0
	TRB->DTDEVO    := TNF->TNF_DTDEVO
EndIf

Return
