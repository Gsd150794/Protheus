/*
===============================================================================================================================
                                    ATUALIZACOES SOFRIDAS DESDE A CONSTRUÇAO INICIAL
===============================================================================================================================
       Autor      |    Data    |                                           Motivo                                              
-------------------------------------------------------------------------------------------------------------------------------
 Alex Wallauer    | 24/08/2017 | Ajuste para o Tratamento da Operação Triangular - Chamado 14473
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "RwMake.ch"
/*
===============================================================================================================================
Programa----------: AOMS016()
Autor-------------: Frederico O. C. Jr
Data da Criacao---: 30/07/2009 
===============================================================================================================================
Descrição---------: Executado quando o cliente ou vendedor sao digitados no pedido de venda, pois o percentual de comissao dos
                    produtos deve ser recalculado, sempre que uma destas entidades eh digitada ou alterada no pedido.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================*/
User Function AOMS016()

Local aArea :=	FWGetArea()
Local nX := 0
Local nN := N //Restaura o valor de n, que eh a variavel publica do protheus que indica a linha do aCols.

//Processa todos os itens do Pedido.
For nX := 1 To Len(aCols)
	//Muda o valor de N.
	N := nX
	
	//Chama a funcao de recalculo da comissao.
	U_AOMS013(.T.)
Next nX

//Restaura o valor da variavel padrao.
N := nN

//Refresh para atualizacao do Rodape do Pedido de Venda.
If Type("oGetDad") = 'O' .And. Type("oGetDad:oWnd") = 'O'//Ajuste para o Tratamento da Operação Triangular
	Ma410Rodap(oGetDad)
	oGetDad:Refresh()       
EndIf

FWRestArea(aArea)
Return
