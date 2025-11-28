/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT340B2
Autor-------------: André Lisboa
Data da Criacao---: 07/11/2014
Descrição---------: O ponto se encontra logo após a atualização dos campos B2_QATU, B2_VATU1, B2_VATU2, B2_VATU3, B2_VATU4
					e B2_VATU5 da tabela SB2 com a tabela SD3 referente ao ajuste de inventario.
					Gravar na tabela SB7 a data em que foi rodado o acerto e alterar o campo Processado para "Sim".
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MT340B2()
  
N_ALIAS:=SELECT()

N_ORDB7:=SB7->(INDEXORD())
N_REGB7:=SB7->(RECNO())
      
N_ORDD3:=SD3->(INDEXORD())
N_REGD3:=SD3->(RECNO())


C_FILIAL  :=SD3->D3_FILIAL
D_DTASEL  :=MV_PAR01  //DATA SELECAO
C_PROD    :=SD3->D3_COD
C_ARMAZ   :=SD3->D3_LOCAL
C_NUMSEQD3:=SD3->D3_NUMSEQ
C_EMISSAO :=SD3->D3_EMISSAO

C_DOCTODE :=MV_PAR11
C_DOCTOATE:=MV_PAR12

SB7->(DBSetOrder(4)) //B7_FILIAL+B7_COD+B7_LOCAL+B7_DOC+B7_DATA

DBSelectArea("SB7")
DBSeek(C_FILIAL+C_PROD+C_ARMAZ+C_DOCTODE+DToS(D_DTASEL))
If RTRIM(B7_DOC)>=RTRIM(C_DOCTODE) .And. RTRIM(B7_DOC)<=RTRIM(C_DOCTOATE)
	RecLock("SB7",.F.)
	SB7->B7_I_ACERT := "1"
	SB7->B7_I_DTACE := Date()
	MSUnLock()
EndIf

Return
