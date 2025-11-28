/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor    |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
 ==============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================

/*
===============================================================================================================================
Programa----------: M410AGRV
Autor-------------: Alex Wallauer Ferreira
Solicitante-------: Andre Carvalho
Data da Criacao---: 14/07/2023
===============================================================================================================================
Descrição---------: Chamado 44097. P. E. antes de operações de Inclusão/Exclusão/Cópia/Alteração no Pedido de Vendas.
------------------: Executa da Função A410Grava() dentro do programa MATN410.PRW 
===============================================================================================================================
Parametros--------: ParamIXB[1] = indica a operação: 1 - inclusão / 2 - alteração / 3 - exclusão	
===============================================================================================================================
Retorno-----------: .T. => O programa não faz nada com o retorno.
===============================================================================================================================
*/
User Function M410AGRV()
Local _nOpc:= ParamIXB[1]  // indica a operação: 1 - inclusão / 2 - alteração / 3 - exclusão	
Local _nX
Local _nColPr,_nColCF,_nColCS,_nColOC,_nColOF
Local _cITFLNT2104,_cITGPNT2104,_cITCFNT2104,_cITCSNT2104

If  _nOpc == 3// SE É EXCLUSAO NÃO FAZ NADA
   Return .T.
EndIf

_nColPr:=aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == 'C6_PRODUTO' } ) 
_nColCF:=aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == 'C6_CF'      } ) 
_nColCS:=aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == 'C6_CLASFIS' } ) 
_nColOC:=aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == 'C6_OBSFCMP' } ) 
_nColOF:=aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == 'C6_OBSFISC' } ) 

_cITFLNT2104:= U_ITGETMV("ITFLNT2104","93/95/96/97/98")//Parâmetro para controlar filiais: ITFLNT2104;
_cITGPNT2104:= U_ITGETMV("ITGPNT2104","0001/0003/0004/0005/0008/0018/0019/0022")//Parâmetro para definir grupo de produtos: ITGPNT2104;
_cITCFNT2104:= U_ITGETMV("ITCFNT2104","5403")          //Parâmetro para definir CFOPs: ITCFNT2104;
_cITCSNT2104:= U_ITGETMV("ITCSNT2104","010")           //Parâmetro para definir CSTs: ITCSNT2104;

// // Criar em ponto de entrada na gravação dos pedidos de venda (MATA410) para quando:
// // - filiais --> 93, 95, 96, 97 e 98
// // - grupo de produtos --> 0001/0003/0004/0005/0008/0018/0019/0022
// // - C6_CF(CFOP) e c6_ (CST) --> 5403, 10
// // Gravar os campos com os seguintes conteúdos:
// // - C6_OBSFCMP --> "cBenef"
// // - C6_OBSFISC --> "PR830001"

If xFilial("SC5") $ _cITFLNT2104
   For _nX := 1 To Len( aCols )
       If LEFT(aCols[_nX,_nColPr],4) $ _cITGPNT2104 .AND.;
	      AllTrim(aCols[_nX,_nColCF]) $ _cITCFNT2104 .And. AllTrim(aCols[_nX,_nColCS]) $ _cITCSNT2104
   
          aCols[_nX,_nColOC] := "cBenef"
          aCols[_nX,_nColOF] := "PR830001"
       EndIf
   Next
EndIf

Return( .T. )

