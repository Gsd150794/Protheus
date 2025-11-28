/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |14/08/2024| Chamado 46163. Vanderlei. Ajustes para não copiar conteúdo campo Protocolo Pedido TMS( C5_I_CDTMS)
Alex Wallauer |21/03/2025| Chamado 50197. Novo tratamento para cortes e desmembramentos de pedidos - INICIAR: M->C5_I_BLSLD = "N"
Lucas Borges  |02/10/2025| Chamado 51526. Modificada forma para recuperar a matrícula do usuário.
===============================================================================================================================
*/

#Include "TopConn.ch"

/*
===============================================================================================================================
Programa----------: MT410CPY
Autor-------------: Frederico O. C. Jr
Data da Criacao---: 22/09/2008
Descrição---------: Ponto de Entrada na chamada da copia do Pedido de Venda
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MT410CPY

Local _nX		:= 0
Local _nPos		:= 0
Local _nPosLib	:= 0
Local _nPosBl	:= 0
Local _nProd	:= 0
Local _nPrcVen	:= 0
Local _nComis1	:= 0
Local _nComis2	:= 0
Local _nComis3	:= 0
Local _nComis4	:= 0
Local _nComis5	:= 0
Local _cFilCarreg := ""
Local _nPosPBTI := 0

// Guarda os dados do usuário
M->C5_I_CDUSU := FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3]

// Tratamento para PV vinculados
If M->C5_I_AGEND $ 'I/O' //Faz antes de limpar os campos pq usa a variavel M->C5_I_OPER para calcular
   _cFilCarreg := xFilial("SC5")
   If ! Empty(M->C5_I_FLFNC)
      _cFilCarreg := M->C5_I_FLFNC
   EndIf 

   M->C5_I_DTENT:=DATE()+U_OMSVLDENT(DATE(),M->C5_CLIENT,M->C5_LOJACLI,M->C5_I_FILFT,M->C5_NUM,1,.F.,_cFilCarreg,M->C5_I_OPER,M->C5_I_TPVEN)   
EndIf

// Configura na cópia de pedidos os campos customizados que devem inicializar vazios
M->C5_I_LIBL  := CTOD(" ")
M->C5_I_LIBCD := CTOD(" ") 
M->C5_I_DTLIC := CTOD(" ")
M->C5_I_DTLIB := CTOD(" ")	// inicializar o campo refrente de dt. liberação vazio
M->C5_I_DTLIP := CTOD(" ")
M->C5_I_PLIBP := CTOD(" ")
M->C5_I_DTRET := CTOD(" ")
M->C5_I_DTSAG := CTOD(" ")
M->C5_I_DTCLI := CTOD(" ")
M->C5_I_DTPRV := CTOD(" ")
M->C5_I_DLIBE := CTOD(" ")
M->C5_I_QTPA  := 0
M->C5_I_LIBCV := 0
M->C5_I_LIBC  := 0
M->C5_I_VLIBB := 0
M->C5_I_QLIBB := 0
M->C5_I_VLIBP := 0
M->C5_I_QLIBP := 0
M->C5_I_PSORI := 0
M->C5_PBRUTO  := 0
M->C5_VOLUME1 := 0
M->C5_I_ENVRD := "N" 
M->C5_I_BLSLD := "N" 

// \/\/\/\/\/\/\/\/\/ *!! ATENCAO !!* SEMPRE INICIAR AS VARIAVEIS DE MEMORIA CARACTERES COM Space(Len(CAMPO)) PQ COM "" O CAMPO FICA INDIGITAVEL ******************************//
M->C5_I_MTBON := Space(Len(SC5->C5_I_MTBON))
M->C5_I_STAWF := Space(Len(SC5->C5_I_STAWF))
M->CC5_CODA1U := Space(Len(SC5->C5_I_NFSED))
M->CC5_I_ARQOP:= Space(Len(SC5->C5_I_NFSED))
M->C5_I_NFSED := Space(Len(SC5->C5_I_NFSED))
M->C5_I_NFREF := Space(Len(SC5->C5_I_NFREF))
M->C5_I_SERNF := Space(Len(SC5->C5_I_SERNF))
M->C5_I_PVREF := Space(Len(SC5->C5_I_PVREF))
M->C5_I_TAB   := Space(Len(SC5->C5_I_TAB  ))// inicializar o campo Tabela de Preço a bloqueio vazio
M->C5_TABELA  := Space(Len(SC5->C5_TABELA ))// Esse campo dever ser sempre limpo pq ele é usado na validacao da condicao de pagamento 
M->C5_I_IDPED := Space(Len(SC5->C5_I_IDPED))
M->C5_I_OPER  := Space(Len(SC5->C5_I_OPER ))
M->C5_I_NPALE := Space(Len(SC5->C5_I_NPALE))// não preencher o código do pedido de Pallet com o código do Pedido original
M->C5_I_LIBCT := Space(Len(SC5->C5_I_LIBCT))
M->C5_I_LIBCA := Space(Len(SC5->C5_I_LIBCA))
M->C5_I_MOTLB := Space(Len(SC5->C5_I_MOTLB))
M->C5_I_LLIBB := Space(Len(SC5->C5_I_LLIBB))
M->C5_I_CLILB := Space(Len(SC5->C5_I_CLILB))
M->C5_I_ULIBB := Space(Len(SC5->C5_I_ULIBB))
M->C5_I_MOTBL := Space(Len(SC5->C5_I_MOTBL))
M->C5_I_BLCRE := Space(Len(SC5->C5_I_BLCRE))
M->C5_I_BLOQ  := Space(Len(SC5->C5_I_BLOQ ))
M->C5_I_MOTLP := Space(Len(SC5->C5_I_MOTLP))
M->C5_I_LLIBP := Space(Len(SC5->C5_I_LLIBP))
M->C5_I_CLILP := Space(Len(SC5->C5_I_CLILP))
M->C5_I_ULIBP := Space(Len(SC5->C5_I_ULIBP))
M->C5_I_HLIBP := Space(Len(SC5->C5_I_HLIBP))
M->C5_I_HLIBE := Space(Len(SC5->C5_I_HLIBE))
M->C5_I_BLPRC := Space(Len(SC5->C5_I_BLPRC))
M->C5_I_MLIBP := Space(Len(SC5->C5_I_MLIBP))
M->C5_I_PDFT  := Space(Len(SC5->C5_I_PDFT ))    
M->C5_I_PDPR  := Space(Len(SC5->C5_I_PDPR ))
M->C5_I_CARGA := Space(Len(SC5->C5_I_CARGA))
M->C5_I_PODES := Space(Len(SC5->C5_I_PODES))
M->C5_I_HRRET := Space(Len(SC5->C5_I_HRRET))
M->C5_I_STATU := Space(Len(SC5->C5_I_STATU))
M->C5_VEICULO := Space(Len(SC5->C5_VEICULO))
M->C5_I_PVDUE := Space(Len(SC5->C5_I_PVDUE))
M->C5_I_PEDOP := Space(Len(SC5->C5_I_PEDOP))
M->C5_I_EXPOP := Space(Len(SC5->C5_I_EXPOP))
M->C5_I_PEDDW := Space(Len(SC5->C5_I_PEDDW)) 
M->C5_I_ENVML := Space(Len(SC5->C5_I_ENVML))
M->C5_I_BLOG  := Space(Len(SC5->C5_I_BLOG ))
M->C5_I_PEDPA := Space(Len(SC5->C5_I_PEDPA))
M->C5_I_PEDGE := Space(Len(SC5->C5_I_PEDGE))
M->C5_I_OPTRI := Space(Len(SC5->C5_I_OPTRI))// Tratamento da Operação Triangular
M->C5_I_PVREM := Space(Len(SC5->C5_I_PVREM))// Tratamento da Operação Triangular
M->C5_I_PVFAT := Space(Len(SC5->C5_I_PVFAT))// Tratamento da Operação Triangular
M->C5_I_CLIEN := Space(Len(SC5->C5_I_CLIEN))// Tratamento da Operação Triangular
M->C5_I_LOJEN := Space(Len(SC5->C5_I_LOJEN))// Tratamento da Operação Triangular
M->C5_I_PEVIN := Space(Len(SC5->C5_I_PEVIN))// Tratamento para PV vinculados
M->C5_ESPECI1 := Space(Len(SC5->C5_ESPECI1))// Tratamento para PV vinculados
M->C5_I_HREMI := TIME()//Space(Len(SC5->C5_I_HREMI))

M->C5_I_HRUWF := Space(Len(SC5->C5_I_HRUWF))
M->C5_I_DTUWF := CTOD(" ")
M->C5_I_ENVML := Space(Len(SC5->C5_I_ENVML))

M->C5_I_PESBR := 0 
M->C5_PBRUTO  := 0
M->C5_DESCONT := 0

If M->C5_TPFRETE = "R"
   M->C5_TPFRETE:="C"
EndIf
If SC5->(FIELDPOS("C5_I_CDTMS")) > 0 
   M->C5_I_CDTMS:= Space(Len(SC5->C5_I_CDTMS)) // Protocolo de integração de Pedidos TMS Multiembarcador.  
EndIf
// /\/\/\/\/\/\/\/\/\ *!! ATENCAO !!* SEMPRE INICIAR AS VARIAVEIS DE MEMORIA CARACTERES COM Space(Len(CAMPO)) PQ COM "" O CAMPO FICA INDIGITAVEL ******************************//

// Configura os campos do GRID (SC6) para que inicializem vazios na cópia de pedidos
_nPos		:= aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == 'C6_I_LIBPE' } )
_nPosLib	:= aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == 'C6_I_LIBPR' } )
_nPosBl	    := aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == 'C6_I_BLPRC' } ) // Para Limpar ou popular o campo de bloqueio de preço
_nProd		:= aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == 'C6_PRODUTO' } ) // Para Limpar ou popular o campo de bloqueio de preço
_nPrcVen	:= aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == 'C6_PRCVEN'  } ) // Para Limpar ou popular o campo de bloqueio de preço
_nPrcOri 	:= aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == "C6_I_VLIBP"	} ) // AWF - 09/11/2016 
_nPLIBP 	:= aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == "C6_I_PLIBP"	} ) // AWF - 22/12/2016 
_nDLIBP 	:= aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == "C6_I_DLIBP"	} ) // AWF - 22/12/2016 

_nComis1	:= aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == "C6_COMIS1"	} )
_nComis2 	:= aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == "C6_COMIS2"	} )
_nComis3 	:= aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == "C6_COMIS3"	} )
_nComis4 	:= aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == "C6_COMIS4"	} )
_nComis5 	:= aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == "C6_COMIS5"	} )

_nPrnet := aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == 'C6_I_PRNET' } )
_nVflet := aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == 'C6_I_VFLET' } )
_nVflex := aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == 'C6_I_VFLEX' } )
_nVltab := aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == 'C6_I_VLTAB' } )
_nPrMin := aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == 'C6_I_PRMIN' } )
_cItdw  := aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == 'C6_I_ITDW'  } )

_cLlibp  := aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == 'C6_I_LLIBP' } )
_cClilp  := aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == 'C6_I_CLILP' } )
_nQtlop  := aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == 'C6_I_QTLIP' } )
_cMotlp  := aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == 'C6_I_MOTLP' } )
 
_nPosPBTI := aScan(aHeader,{|x| AllTrim(x[2])=="C6_I_PTBRU"})  

For _nX := 1 To Len( aCols )
// \/\/\/\/\/\/\/\/\/  *!! ATENCAO !!* SEMPRE INICIAR AS VARIAVEIS DE MEMORIA CARACTERES COM Space(Len(CAMPO)) PQ COM "" O CAMPO FICA INDIGITAVEL ******************************//
	aCols[_nX][_nPos   ] := Space(Len(SC6->C6_I_LIBPE))
	aCols[_nX][_nPosLib] := Space(Len(SC6->C6_I_LIBPR))
	aCols[_nX][_nPosBl ] := Space(Len(SC6->C6_I_BLPRC))
	aCols[_nX][_cItdw  ] := Space(Len(SC6->C6_I_ITDW ))
	aCols[_nX][_cLlibp ] := Space(Len(SC6->C6_I_LLIBP))
	aCols[_nX][_cClilp ] := Space(Len(SC6->C6_I_CLILP))
	aCols[_nX][_cMotlp ] := Space(Len(SC6->C6_I_MOTLP))
// /\/\/\/\/\/\/\/\/\  *!! ATENCAO !!* SEMPRE INICIAR AS VARIAVEIS DE MEMORIA CARACTERES COM Space(Len(CAMPO)) PQ COM "" O CAMPO FICA INDIGITAVEL ******************************//
	aCols[_nX][_nPLIBP]  := CTOD("")// AWF - 22/12/2016  
	aCols[_nX][_nDLIBP]  := CTOD("")// AWF - 22/12/2016 
	aCols[_nX][_nPrcOri] := 0// AWF - 09/11/2016 
	aCols[_nX][_nComis1] := 0
	aCols[_nX][_nComis2] := 0
	aCols[_nX][_nComis3] := 0
	aCols[_nX][_nComis4] := 0
	aCols[_nX][_nComis5] := 0
	aCols[_nX][_nPrnet ] := 0 
	aCols[_nX][_nVflet ] := 0
	aCols[_nX][_nVflex ] := 0
	aCols[_nX][_nVltab ] := 0
	aCols[_nX][_nPrMin ] := 0
	aCols[_nX][_nQtlop ] := 0
 	aCols[_nX][_nPosPBTI] := 0  
Next _nX

//Marca se tem bloqueio de bonificação
If u_vldPedBon( aCols )
	M->C5_I_BLOQ := "B"
EndIf 
	
Return

