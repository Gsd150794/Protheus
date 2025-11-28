/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |03/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Alex Wallauer |13/06/2024| Chamado 47518. Andre. SB1 posicionado corretamente.
Julio Paz     |17/01/2025| Chamado 48539.Salva em uma variáveStaticic as quantidades dos itens para validar no Recalculo das 
			  |			 | quantidades dos itens de pedidos de compras do tipo serviço, conforme regras definidas.
===============================================================================================================================
*/

#Include "TOTVS.ch"

Static _aQtdProd := {}

/*
===============================================================================================================================
Programa----------: MT103IPC
Autor-------------: Tiago Correa
Data da Criacao---: 30/09/2009
Descrição---------: P.E. para adicionar informações que estão no Pedido de Compras para os campos da Nota de Entrada
					Localização: Funções: NFePC2Acol() e LxA103SC7ToaCols()  (MATA103X.PRX e LOCXNF2.PRW), após a carga de dados
					do pedido de compras.
					Em que ponto: Este Ponto de Entrada tem por objetivo atualizar os campos customizados no Documento de Entrada
					e na Pré Nota de Entrada após a importação dos itens do Pedido de Compras (SC7).
Parametros--------: ExpN1 -> N -> Contém o número do item do aCols do Documento de Entrada e da Pré Nota de Entrada.
Retorno-----------: lRet -> L -> O parâmetro lRet, somente é tratado na rotina Localizada. "LocxNF2".
					Em outros ambientes, este parâmetro não possui aplicação.
					.T. = Indica que a TES carregada no Acols, será mantida.
					Se não For passado TES no Acols, será substituída pela TEs do Pedido de Compras / Cadastro de Produtos.
					.F. = Indica que a TES do aCols, poderá ser substituída pela TEs do Pedido de Compras / Cadastro de Produtos.
					(Este é o funcionamento padrão mesmo quando não existe o Ponto de Entrada)
===============================================================================================================================
*/
User Function MT103IPC

Local _aArea 	 := SB1->(GetArea())
Local _nCols 	 := Len(aCols)
Local _nPosCod	 := aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == "D1_COD"     } )
Local _nPosDir	 := aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == "D1_I_DIRCR" } )
Local _nPosDes	 := aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == "D1_I_DESC"  } )
Local _nPosPedC	 := aScan( aHeader , {|X| Upper( AllTrim( X[2])) == "D1_PEDIDO"  } ) // Numero do Pedido de Compras
Local _nPosItemP := aScan( aHeader , {|X| Upper( AllTrim( X[2])) == "D1_ITEMPC"	 } ) // Item do Pedido de Compras
Local _nPosQtd   := aScan( aHeader , {|X| Upper( AllTrim( X[2])) == "D1_QUANT"	 } ) // Quantidade na 1ª U.M.
Local _nPosItn   := aScan( aHeader , {|X| Upper( AllTrim( X[2])) == "D1_ITEM"	 } ) // Item do Documento
Local _nI  

//====================================================================================================
// Grava campos da Nota Fiscal com informacoes do Pedido de Compra
//====================================================================================================
SB1->(DBSetOrder(1))
If SB1->(DBSeek(xFilial()+aCols[_nCols][_nPosCod]))
   aCols[_nCols][_nPosDir] := SB1->B1_I_DIRCR
   aCols[_nCols][_nPosDes] := SB1->B1_DESC
EndIf

//==========================================================
// Grava em uma variáveStaticic os Produtos e quantidades
// que possuem controle de entregas parcias, para serem
// utilizados nas validações da digitação da nota fiscal 
// de entrada.
//==========================================================
SC7->(DBSetOrder(1)) // C7_FILIAL+C7_NUM+C7_ITEM+C7_SEQUEN  

For _nI := 1 To Len(aCols)
    If !aCols[_nI][Len(aHeader)+1] //Não verifica linhas deletadas
	   If SC7->(MsSeek(xFilial("SC7")+aCols[_nI][_nPosPedC]+aCols[_nI][_nPosItemP]))
	      If SC7->C7_I_SVPAR == "S" // Controla Entregas Parciais. Faturamento parcial para produtos do tipo Serviço.
             aAdd(_aQtdProd,{aCols[_nCols][_nPosCod],;   // Codigo Produto                     1
                             aCols[_nCols][_nPosItn],;   // Item da Nota                       2
							 aCols[_nCols][_nPosQtd],;   // Quantidade                         3
							 aCols[_nCols][_nPosPedC],;  // Pedido de Compra                   4
							 aCols[_nCols][_nPosItemP],; // Item Pedido de Compra              5
							 SC7->C7_PRECO})             // Preço do item do pedido de compra  6
          EndIf 
	   EndIf
	EndIf 
Next 

FWRestArea(_aArea)

Return( .T. )

/*
===============================================================================================================================
Programa----------: MT103RTQ
Autor-------------: Julio de Paula Paz
Data da Criacao---: 10/01/2025
Descrição---------: Retorna o ArStaticatic _aQtdProd que possui os produtos e quantidades que possuem controle de entregas
                    parciais. Para serem utilizados nas validações da digitação da nota fiscal de entrada.
Parametros--------: Nenhum
Retorno-----------: _aRet = Array com produtos e quantidades dos itens do pedido de compras que possuem controle de entregas
                    parciais. 
					São quantidades disponíveis antes das alterações do usuário, para serem utilizadas nas validações.
===============================================================================================================================
*/
User Function MT103RTQ

Local _aRet := _aQtdProd 

Return _aRet 
