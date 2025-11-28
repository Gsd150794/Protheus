/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |12/07/2021| Chamado 37002. Corrigir a Subtração das Notas de devolução das notas de vendas funcionarios.
Alex Wallauer |01/03/2024| Chamado 46434. Fernando. Correção da coluna TOTAL_DEV para SUM(D1.D1_TOTAL+D1.D1_VALIPI).
Alex Wallauer |25/06/2024| Chamado 47331. Andre. Ajustado para considerar funcionarios demitidos sem cpf em outra matricula.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "rwmake.ch"

/*
===============================================================================================================================
Programa----------: MGPE003
Autor-------------: Fabiano Dias/Hede
Data da Criacao---: 28/02/2011
Descrição---------: Rotina desenvolvida para possibilitar a geracao de arquivo .txt com o somatorio total vendido por funcionario
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE003()


Private _cPerg   := "MGPE003"              

Private _cFile
Private _cArqTxt
Private _nHdl  
Private _cEOL    := 	CHR(13)+CHR(10)  

Private _ogeratxt

Begin Sequence 

   Pergunte(_cPerg,.F.)

   //===========================================================================
   // Montagem da tela de processamento.                                  
   //===========================================================================
   _lSair:=.T.
   @ 200,1 TO 400,380 DIALOG _ogeratxt TITLE OemToAnsi("Geracao de Arquivo Texto")
   @ 02,03 TO 080,190
   @ 20,018 Say " Este programa ira gerar um arquivo texto, conforme os parametros     "
   @ 40,018 Say " definidos  pelo usuario,  contendo a filial, matrícula do funcionário"
   @ 60,018 Say " e total das compras efetuadas por este no período filtrado.          "

   @ 85,100 BMPBUTTON Type 01 ACTION (Processa({|| _lSair:=MGPE003DA() },"Aguarde processando os dados..."), If(_lSair,_ogeratxt:End(),) )
   @ 85,130 BMPBUTTON Type 05 ACTION Pergunte(_cPerg,.T.)      
   @ 85,160 BMPBUTTON Type 02 ACTION Close(_ogeratxt)

   Activate Dialog _ogeratxt Centered 

   FClose(_nHdl)

End Sequence 

Return .F.

/*
===============================================================================================================================
Programa----------: MGPE003DA
Autor-------------: Fabiano Dias/Hede
Data da Criacao---: 28/02/2011
Descrição---------: Funcao que lê os dados e gera o arquivo
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE003DA() 
                      
Local _cQuery      := ""  
Local _nCountRec   := 0       
Local _cLin 

Private _cAliasSD2:= GetNextAlias()                                                                

cTitle:="Geracao de Arquivo Texto - Hora Inicial: "+Time()

_cArqTxt := AllTrim(AllTrim(MV_PAR06))

If Empty(_cArqTxt) .Or. ! ("TXT" $ Upper(_cArqTxt))
    U_ITMsg("Local de destino do arquivo ou o nome do arquivo não foi informado.","Atenção",,1)
    Return .F.
EndIf 

_nHdl    := FCreate(_cArqTxt)

If _nHdl == -1

    U_ITMsg("O arquivo de nome " + _cArqTxt + " nao pode ser criado!","Atenção",'Verifique os parametros.',1)
   	//MsgAlert("O arquivo de nome " + _cArqTxt + " nao pode ser criado! Verifique os parametros.","Atencao!")
	Return .F.

EndIf     
                   
//===========================================================================
//Validacoes dos Parametros
//===========================================================================

If Empty(MV_PAR01) .Or. Empty(MV_PAR03) .Or. Empty(MV_PAR04) .Or. Empty(MV_PAR05) .Or. Empty(MV_PAR06)

	xMagHelpFis("Campos Obrigatórios","Para executar esta rotina é necessário que se preencha TODOS os parâmetros.",;
				"Favor informar parâmetros novamente.")  
	Return.F.		     
				
EndIf            

ProcRegua(3) 
IncProc("Lendo dados, Aguarde...")
IncProc("Lendo dados, Aguarde...")
//===========================================================================
//Query principal
//===========================================================================

_cQuery := "SELECT QRY1.RA_FILIAL, QRY1.RA_MAT,QRY1.RA_CIC,QRY1.RA_NOME,QRY1.RA_SITFOLH, (QRY1.TOTAL_VEN - COALESCE(QRY2.TOTAL_DEV,0)) TOTAL FROM "
_cQuery += "(SELECT RA.RA_FILIAL,RA.RA_MAT,RA.RA_CIC,RA.RA_NOME,RA.RA_SITFOLH, COALESCE(SUM(D2.D2_VALBRUT),0) TOTAL_VEN "
_cQuery += "FROM " + RetSqlName("SRA") + " RA "
_cQuery += "INNER JOIN " + RetSqlName("SA1") + " A1 ON A1.A1_CGC = RA.RA_CIC "
_cQuery += "INNER JOIN " + RetSqlName("SD2") + " D2 ON D2.D2_CLIENTE = A1.A1_COD AND D2.D2_LOJA = A1.A1_LOJA "
_cQuery += "INNER JOIN " + RetSqlName("ZAY") + " ZAY ON ZAY.ZAY_CF = D2.D2_CF "
_cQuery += "INNER JOIN " + RetSqlName("SF4") + " SF4 ON SF4.F4_FILIAL = D2.D2_FILIAL AND SF4.F4_CODIGO = D2.D2_TES AND SF4.F4_DUPLIC <> 'S' AND SF4.D_E_L_E_T_ = ' '  "
_cQuery += "WHERE RA.D_E_L_E_T_ = ' ' "
_cQuery += "AND D2.D_E_L_E_T_ = ' ' "
_cQuery += "AND A1.D_E_L_E_T_ = ' ' " 
_cQuery += "AND ( RA.RA_CATFUNC = 'M' OR RA.RA_CATFUNC = 'E' ) "
_cQuery += "AND ZAY.ZAY_TPOPER = 'V' "
_cQuery += "AND RA.RA_FILIAL = '" + MV_PAR01 +"' "
_cQuery += "AND (RA.RA_DEMISSA = ' ' OR RA.RA_DEMISSA BETWEEN '" + DToS(MV_PAR04) + "' AND '" + DToS(MV_PAR05) + "') "
_cQuery += "AND RA.RA_MAT BETWEEN '" + MV_PAR02 + "' AND '" + MV_PAR03 + "' "
_cQuery += "AND D2.D2_EMISSAO BETWEEN '" + DToS(MV_PAR04) + "' AND '" + DToS(MV_PAR05) + "' "
_cQuery += "GROUP BY RA.RA_FILIAL,RA.RA_MAT,RA.RA_CIC,RA.RA_NOME,RA.RA_SITFOLH "
_cQuery += ") QRY1 "
_cQuery += "LEFT JOIN ( "
_cQuery += "SELECT RA.RA_FILIAL,RA.RA_MAT,RA.RA_CIC,RA.RA_NOME,RA.RA_SITFOLH, COALESCE(SUM(D1.D1_TOTAL+D1.D1_VALIPI),0) TOTAL_DEV "
_cQuery += "FROM " + RetSqlName("SRA") + " RA "
_cQuery += "INNER JOIN " + RetSqlName("SA1") + " A1 ON A1.A1_CGC = RA.RA_CIC "
_cQuery += "INNER JOIN " + RetSqlName("SD1") + " D1 ON D1.D1_FORNECE = A1.A1_COD AND D1.D1_LOJA = A1.A1_LOJA "
_cQuery += "INNER JOIN " + RetSqlName("SF4") + " SF4 ON SF4.F4_FILIAL = D1.D1_FILIAL AND SF4.F4_CODIGO = D1.D1_TES AND SF4.F4_DUPLIC <> 'S' AND SF4.D_E_L_E_T_ = ' '  "
_cQuery += "WHERE RA.D_E_L_E_T_ = ' ' "
_cQuery += "  AND D1.D_E_L_E_T_ = ' ' "
_cQuery += "  AND A1.D_E_L_E_T_ = ' ' "
_cQuery += "  AND ( RA.RA_CATFUNC = 'M' OR RA.RA_CATFUNC = 'E' ) "
_cQuery += "  AND D1.D1_TIPO = 'D' "
_cQuery += "  AND RA.RA_FILIAL = '" + MV_PAR01 +"' "
_cQuery += "  AND (RA.RA_DEMISSA = ' ' OR ( RA.RA_DEMISSA BETWEEN '" + DToS(MV_PAR04) + "' AND '" + DToS(MV_PAR05) +"' "
_cQuery += "  AND NOT EXISTS (SELECT 'Y' FROM " + RetSqlName("SRA") + " SRA2 "//IGNORAR OS DEMITIDOS QUE FORAM ADMITIDOS NO MESMO MES Ex. Aprediz para CLT
_cQuery += "  	               WHERE SRA2.D_E_L_E_T_ = ' ' AND SRA2.RA_CIC = RA.RA_CIC AND SRA2.RA_SITFOLH <> 'D' AND SRA2.RA_DEMISSA = ' ') "
_cQuery += "  )   )"
_cQuery += "  AND A1.A1_FILIAL = '" + xFilial("SA1") +"' "
_cQuery += "  AND RA.RA_MAT BETWEEN '" + MV_PAR02 + "' AND '" + MV_PAR03 + "' "
_cQuery += "  AND D1.D1_EMISSAO BETWEEN '" + DToS(MV_PAR04) + "' AND '" + DToS(MV_PAR05) + "' "
_cQuery += "GROUP BY RA.RA_FILIAL,RA.RA_MAT,RA.RA_CIC,RA.RA_NOME,RA.RA_SITFOLH "
_cQuery += ") QRY2 ON QRY1.RA_FILIAL = QRY2.RA_FILIAL AND QRY1.RA_MAT = QRY2.RA_MAT "
_cQuery += "ORDER BY QRY1.RA_FILIAL,QRY1.RA_MAT "
 
If Select(_cAliasSD2) > 0
	(_cAliasSD2)->(DBCloseArea())
EndIf
 
dbUseArea( .T., "TOPCONN",TcGenQry(,,_cQuery),_cAliasSD2,.T.,.T.)

IncProc("Lendo dados, Aguarde...")

COUNT TO _nCountRec //Contabiliza o numero de registros encontrados pela query

If _nCountRec = 0 
   U_ITMsg("Não há resgistros para esses filtros.","Atenção",'Filtre novamente com outros dados.',1)
   Return .F.
EndIf
	
(_cAliasSD2)->(DBGoTop())     
	
//===========================================================================
//Percorre todos os registros selecionados na query 
//===========================================================================
aDet:={}
aDetEx:={}
_aTit:={}
_aCabXML:={}
// Alinhamento: 1-Left   ,2-Center,3-Right
// Formatação.: 1-General,2-Number,3-Monetário,4-DateTime
//             Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
//   (_aCabXML,{Titulo             ,1           ,1         ,.F.       })
aAdd(_aTit,'Filial')
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//01
aAdd(_aTit,'Matricula')
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//02
aAdd(_aTit,'Nome')
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,1           ,1         ,.F.})//03
aAdd(_aTit,'Valor')
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,3           ,3         ,.F.})//04
aAdd(_aTit,'CPF')
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//05
aAdd(_aTit,'Situação')
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//05

cTot:=AllTrim(Str(_nCountRec))
nConta:=0
ProcRegua(_nCountRec)

While (_cAliasSD2)->(!Eof())        
	
    nConta++
    IncProc('Lendo: '+AllTrim(Str(nConta))+" de "+cTot )
	//IncProc("Processando dados matricula: " + (_cAliasSD2)->RA_MAT )  			
    aItem:={}
    aAdd(aItem,(_cAliasSD2)->RA_FILIAL )//01
    aAdd(aItem,(_cAliasSD2)->RA_MAT    )//02
    aAdd(aItem,(_cAliasSD2)->RA_NOME   )//03
    aAdd(aItem,(_cAliasSD2)->TOTAL     )//04
    aAdd(aItem,(_cAliasSD2)->RA_CIC    )//05
    aAdd(aItem,(_cAliasSD2)->RA_SITFOLH)//06
	//Filial
	_cLin 	:= 	PadR((_cAliasSD2)->RA_FILIAL,2) + " "
	_cLin 	+= 	PadR((_cAliasSD2)->RA_MAT,6) + " "		
	_cLin 	+=  PadL(AllTrim(Str((_cAliasSD2)->TOTAL,7,2)),7,"0")    			
	_cLin	+=  _cEOL                
	
	FWrite(_nHdl,_cLin,Len(_cLin))    
    
    aItem[5]:=TRANS((_cAliasSD2)->RA_CIC,"@R 999.999.999-99")//Trans para TELA Excel
    aItemEx:=ACLONE(aItem)//Excel
    aAdd(aDetEx,aItemEx)  //Excel
    aItem[4]:=TRANS((_cAliasSD2)->TOTAL,"@E 999,999.99")//Trans só para TELA 
    aAdd(aDet,aItem)

	(_cAliasSD2)->(DBSkip())

EndDo  
    
//MsgAlert("Arquivo Gerado com Sucesso: "+_cArqTxt)
    
(_cAliasSD2)->(DBCloseArea())

_cTitulo:=cTitle+" - "+DToC(DATE())+" - Hora Final: "+Time()
_cMsgTop:= "Arquivo Gerado com Sucesso: "+_cArqTxt + " - Data Inicial: "+DToC(MV_PAR04) +" - Data Final" + DToC(MV_PAR05)

//                        ,_aCols,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons , _aCab  , bDblClk , _aColXML, bCondMarca,_bLegenda:EVAL(_bLegenda,_aCols,oLbxAux:nAt),_lHasOk,_bHeadClk,_aSX1)
U_ITListBox(_cTitulo,_aTit,aDet  , .T.    , 3    ,_cMsgTop,          ,        ,         ,     ,        ,           ,_aCabXML,         , aDetEx  ,           ,                                            ,       ,         ,     )

Return .T.
