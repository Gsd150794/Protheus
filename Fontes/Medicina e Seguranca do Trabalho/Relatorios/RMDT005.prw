/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaco  |29/09/2022| Chamado 41383 - Incluido parametro de filtro de Situação.
Alex Wallauer |18/04/2023| Chamado 47002 - Fernando. Correção de linhas duplicadas e geração do XLXS.
Igor Melgaco  |03/07/2024| Chamado 47730 - André. Inclusão do campo vencido.  
==============================================================================================================================
*/

#Include "report.ch"
#Include "TOTVS.ch" 

Static _cAlias := ""

/*
===============================================================================================================================
Programa----------: RMDT005
Autor-------------: Igor Melgaço
Data da Criacao---: 19/08/2022
Descrição---------: Relatorio de EPI em uso. Chamado 41009
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RMDT005()

Local nA 
Local _aParRet   := {}
Local _aParAux   := {}
Local _bOK       := {|| .T. }
Local _cTitAux   := "Relatorio de EPI em uso"
Local bBlock     := ""

Private oReport		:= Nil
Private oSecEntr_1	:= Nil

Private _aOrd		:= {} 

Private _cPerg		:= "RMDT005"
Private _nCont		:= 0

_aUso := {"S-Sim","N-Nao"}

MV_PAR01 := Space(100)
MV_PAR02 := Space(100)
MV_PAR03 := Space(100)
MV_PAR04 := Space(1)
MV_PAR05 := CTOD("")
MV_PAR06 := Space(5)

_aItalac_F3:={}

_cSelecSQB := "SELECT QB_FILIAL, QB_DEPTO, QB_DESCRIC FROM "+RETSQLNAME("SQB")+" SQB WHERE  D_E_L_E_T_ = ' '  ORDER BY QB_DEPTO " 
_cSelecSB1 := "SELECT B1_COD, B1_DESC FROM "+RETSQLNAME("SB1")+" SB1 WHERE  B1_GRUPO = '0805' AND D_E_L_E_T_ = ' '  ORDER BY B1_COD " 

aAdd(_aItalac_F3,{"MV_PAR02" ,_cSelecSQB,{|Tab| (Tab)->QB_FILIAL + " - "+ (Tab)->QB_DEPTO },{|Tab| (Tab)->QB_DESCRIC } ,,"Filial - Departamento"   ,          ,          ,60        ,.T.        ,       , } )
aAdd(_aItalac_F3,{"MV_PAR03" ,_cSelecSB1,{|Tab| (Tab)->B1_COD}   ,{|Tab| (Tab)->B1_DESC}     ,,"EPI's"           ,          ,          ,60        ,.T.        ,       , } )

aAdd( _aParAux , { 1 , "Filial"         	 , MV_PAR01, "@!" , "" ,"LSTFIL", "" , 100 , .F. } )
aAdd( _aParAux , { 1 , "Departamento"		 , MV_PAR02, "@!" , "" ,"F3ITLC", "" , 100 , .F. } )
aAdd( _aParAux , { 1 , "EPI"            	 , MV_PAR03, "@!" , "" ,"F3ITLC", "" , 100 , .F. } ) 
aAdd( _aParAux , { 2 , "Em Uso"         	 , MV_PAR04, _aUso, 060,".T.",.T. ,".T."}) 
aAdd( _aParAux , { 1 , "Entrega a partir De" , MV_PAR05, "@D" , "" , ""	, "" , 050 , .F.  })
aAdd( _aParAux , { 1 , "Situacao"	    	 , MV_PAR06, "@!" , "fSituacao()" ,""      , "" , 100 , .F. } ) 

For nA := 1 To Len( _aParAux )
    aAdd( _aParRet , _aParAux[nA][03] )
Next

						//aParametros, cTitle                                , @aRet    ,[bOk], [ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ] 
If !ParamBox( _aParAux , _cTitAux, @_aParRet, _bOK, /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
	Return .F.
EndIf

DEFINE REPORT oReport	NAME		_cPerg ;
						TITLE		"Relatorio de EPI em uso" ;
						PARAMETER	_cPerg ;
						ACTION		{|oReport| RMDT005PR( oReport ) } ;
						Description	"Este relatório emitirá a relação de  EPI em uso."

//====================================================================================================
// Seta Padrao de impressao como Paisagem
//====================================================================================================
oReport:SetLandscape()
oReport:SetTotalInLine(.F.)

oReport:nFontBody	:= 08
oReport:cFontBody	:= "Courier New"
oReport:nLineHeight	:= 45 // Define a altura da linha.

//	DEFINE Section oSecEntr_1 OF oReport TITLE ""  TABLES "TNF"  //ORDERS _aOrd
    oSecEntr_1 := TRSection():New(oReport, "Dados", {""} , , .F. , .T. )


   DEFINE CELL NAME "TNF_FILIAL"	   OF oSecEntr_1 ALIAS "TNF"  TITLE "Filial"          SIZE 02
   DEFINE CELL NAME "RA_MAT"        OF oSecEntr_1 ALIAS "SRA"  TITLE "Matricula"       SIZE 10
   DEFINE CELL NAME "RA_NOME"       OF oSecEntr_1 ALIAS "SRA"  TITLE "Nome"            SIZE 20
   DEFINE CELL NAME "RJ_DESC"   	   OF oSecEntr_1 ALIAS "SRJ"  TITLE "Funcao"          SIZE 20
   DEFINE CELL NAME "QB_DESCRIC"	   OF oSecEntr_1 ALIAS "SQB"  TITLE "Departamento"    SIZE 10
   //DEFINE CELL NAME "RA_SITFOLH"	OF oSecEntr_1 ALIAS "SRA"  TITLE "Situacao"        SIZE 20
   DEFINE CELL NAME "TNF_CODEPI"	   OF oSecEntr_1 ALIAS "TNF"  TITLE "EPI Cod."        SIZE 15  
   DEFINE CELL NAME "B1_DESC"	      OF oSecEntr_1 ALIAS "SB1"  TITLE "EPI Desc."       SIZE 30  
   DEFINE CELL NAME "TNF_NUMCAP"	   OF oSecEntr_1 ALIAS "TNF"  TITLE "C.A."            SIZE 10 
   DEFINE CELL NAME "TN3_DTVENC"	   OF oSecEntr_1 ALIAS "TN3"  TITLE "Data Vencto"     SIZE 15 
   DEFINE CELL NAME "TNF_QTDENT"	   OF oSecEntr_1 ALIAS "TN3"  TITLE "Qtd Entrega"     SIZE 10 PICTURE "@E 99,999,999,999.99" 
   DEFINE CELL NAME "TNF_DTENTR"	   OF oSecEntr_1 ALIAS "TNF"  TITLE "Data Entrega"    SIZE 10 
   DEFINE CELL NAME "TNF_DTDEVO"	   OF oSecEntr_1 ALIAS "TNF"  TITLE "Data Devolucao"  SIZE 10 
   DEFINE CELL NAME "TNF_DIASUSO"	OF oSecEntr_1 ALIAS "TNF"  TITLE "Dias de Uso"     SIZE 20 BLOCK {||IIf(Empty(DToS(QRY1->TNF_DTDEVO)) , DateDiffDay(QRY1->TNF_DTENTR,dDataBase),DateDiffDay(QRY1->TNF_DTDEVO,QRY1->TNF_DTENTR)) } PICTURE "@E 99,999,999,999" 

   bBlock := {||IIf(IIf(Empty(DToS(QRY1->TNF_DTDEVO)) , DateDiffDay(QRY1->TNF_DTENTR,dDataBase),DateDiffDay(QRY1->TNF_DTDEVO,QRY1->TNF_DTENTR)) > IIf(QRY1->TN3_DURABI>0,QRY1->TN3_DURABI,9999999),"Sim","")}

   TRCell():New( oSecEntr_1,"TNF_VENCIDO", "TNF"    , "Vencido?", ""        ,   25    ,          ,  bBlock  ,          ,              ,                ,              ,             ,             ,            , CLR_RED    ,   .T.   )

oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: RMDT005PR
Autor-------------: Igor Melgaço
Data da Criacao---: 19/08/2022
Descrição---------: Executa relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RMDT005PR( oReport )

Local _cFiltro := "% "
Local _aRet := {}
Local cConv := ""

_cAlias     := "QRY1" //GetNextAlias()

//oSecEntr_1:Enable()

If !Empty(MV_PAR01)

	_cFiltro += " AND TNF_FILIAL IN " + FormatIn(MV_PAR01,";") 
	
EndIf

If !Empty(MV_PAR02) 
	
	 _aRet := aClone(RMDT005FOR(MV_PAR02 ))

	_cFiltro += " AND SRA.RA_FILIAL IN " + _aRet[1]
	_cFiltro += " AND SRA.RA_DEPTO IN " + _aRet[2]
	
EndIf

If !Empty(MV_PAR03)

	_cFiltro += " AND TN3.TN3_CODEPI IN " + FormatIn(MV_PAR03,";")
	
EndIf

If Subs(MV_PAR04,1,1) = "S"
	
	_cFiltro += " AND TNF.TNF_DTDEVO  = ' ' " 

EndIf

If !Empty(MV_PAR05) 
	
    _cFiltro += " AND TNF.TNF_DTENTR  >= '" + DToS(MV_PAR05) + "' " 

EndIf

cConv := RMDT005TR(MV_PAR06)

_cFiltro += " AND SRA.RA_SITFOLH  IN " + FormatIn(cConv,";") + " " 



_cFiltro += " AND RA_CATFUNC <> 'A' "

_cFiltro += " %"


	oReport:SetTitle( "Relatorio de EPI em uso" )

	//====================================================================================================
	// Executa query para consultar Dados
	//====================================================================================================
	BEGIN REPORT QUERY oSecEntr_1

		BeginSql Alias _cAlias

			SELECT DISTINCT TNF_FILIAL, RA_MAT, RA_NOME, RA_SITFOLH, RJ_DESC, QB_DESCRIC, TNF_CODEPI, B1_DESC, 
					        TNF_NUMCAP, TN3_DTVENC, TNF_QTDENT, TNF_DTENTR, TNF_DTDEVO, TN3_DURABI

			FROM %Table:TNF% TNF
                LEFT JOIN %Table:TN3% TN3 ON (TN3.TN3_FILIAL = TNF.TNF_FILIAL AND TNF.TNF_CODEPI = TN3.TN3_CODEPI AND TNF.TNF_FORNEC = TN3.TN3_FORNEC AND TNF.TNF_NUMCAP = TN3.TN3_NUMCAP AND TN3.%notDel%)
                LEFT JOIN %Table:SB1% SB1 ON (TN3.TN3_CODEPI = SB1.B1_COD     AND SB1.%notDel%)
                LEFT JOIN %Table:SRA% SRA ON (SRA.RA_FILIAL  = TNF.TNF_FILIAL AND SRA.RA_MAT     = TNF.TNF_MAT    AND SRA.%notDel%)
                LEFT JOIN %Table:SQB% SQB ON (SQB.QB_FILIAL  = SRA.RA_FILIAL  AND SRA.RA_DEPTO   = SQB.QB_DEPTO   AND SQB.%notDel%)
				LEFT JOIN %Table:SRJ% SRJ ON (SRA.RA_CODFUNC = SRJ.RJ_FUNCAO  AND SRJ.%notDel%)

			WHERE TNF.%notDel%
              %Exp:_cFiltro%

			ORDER BY TNF_FILIAL,RA_MAT

		EndSql

    END REPORT QUERY oSecEntr_1

oSecEntr_1:Print(.T.)

Return

/*
===============================================================================================================================
Programa----------: RMDT005FOR
Autor-------------: Igor Melgaço
Data da Criacao---: 19/08/2022
Descrição---------: Função para tratar o MV_PAR02
Parametros--------: cCampo - Departamentos selecionados
Retorno-----------: {_cFilial,_cDepto} - Filial e Departamentos para filtro na query
===============================================================================================================================
*/
Static Function RMDT005FOR(cCampo)

Local _aFilDepto := {}
Local _cDepto    := ""
Local _cFilial   := ""
Local _nTamFilial := 2
Local _nTamProd := Len(SB1->B1_COD)
Local i := 0

_aFilDepto := StrTokArr(cCampo,";")

For i := 1 To Len(_aFilDepto)
	_cFilial += IIf(Empty(AllTrim(_cFilial)),"",",") + "'" + Subs(_aFilDepto[i],1,_nTamFilial) + "'"
	_cDepto  += IIf(Empty(AllTrim(_cDepto)),"",",") + "'" + Subs(_aFilDepto[i]+Space(_nTamProd),6,_nTamProd) + "'"
Next

_cFilial := "("+_cFilial+")"
_cDepto  := "("+_cDepto+")"

Return({_cFilial,_cDepto})

/*
===============================================================================================================================
Programa----------: RMDT005TR
Autor-------------: Igor Melgaço
Data da Criacao---: 19/08/2022
Descrição---------: Função para tratar o MV_PAR06
Parametros--------: cCampo - Situação 
Retorno-----------: cConv - Campo convertido
===============================================================================================================================
*/
Static Function RMDT005TR(cCampo)

Local i := 0
Local cConv := ""

For i := 1 To Len(cCampo)
	cConv += Subs(cCampo,i,1) + ";"
Next

cConv := Subs(cConv,1,Len(cConv)-1)

Return(cConv)
