' TransDump.bas
' Version 1.0 Created 13/04/2005 by Hidenori Yoshizumi
'
''This macro exports English and Japanese strings to CSV file.
' It is possible to select optional field such as "Comment", "Translation Date", "Resource"
'
' Version 1.1 05/10/2005 by Hidenori Yoshizumi
'  - Resouce is default and placed in the second row.
' Version 1.2 12/18/2007 by Sung-Hoon Lim
'  - Changed a variable type from Integer to Long in order to handle a file that has many strings such as MSI.lpu

Option Explicit

'Define Constant
Dim CsvName As String      'CSV file name
Dim bComment As Boolean
Dim bTransDate As Boolean
Dim bResource As Boolean
Dim errorcount As Integer

Sub Main()
  Dim prj As PslProject
  Dim trnlst As PslTransList
  Dim header As String
  Dim title As String, s1 As String, s2 As String, s As String
  Dim filePath As String
  Dim Comment As String
  Dim TransDate As Date
  Dim ResourceName As String
  
  'Hoon : Changed the type from Integer to Long to handle a file that has many strings such as MSI.lpu
  Dim i As Long
  Dim fso
  Dim myfile

  Dim dumy As Integer

  If PSL.Projects.Count < 1 Then
    MsgBox "No project is opened.", vbCritical, "Warning - PageOne"
    Exit Sub
  End If

  Set prj = PSL.ActiveProject

  ' Put put file path
  filePath = prj.Location
  If Right(filePath, 1) <> "\" Then
    filePath = filePath & "\"
  End If
  filePath = filePath & prj.Name & "_reference.csv"

  Set fso = CreateObject("Scripting.FileSystemObject")
  Set myfile = fso.CreateTextFile(filePath, True, True)

  ' Make header for output file
  header = "Title" & Chr(9) & "Resource" & Chr(9) & "Number" & Chr(9) & "ID" & Chr(9) & "English" & Chr(9) & "Localized"
  header = header & Chr(9) & "Comment"
  header = header & Chr(9) & "Translation Date"

  myfile.WriteLine header & Chr(9) &  "Status"


    For Each trnlst In prj.TransLists
      title = GetTitle(trnlst.TargetFile)
      For i = 1 To trnlst.StringCount
        s1 = Trim(trnlst.String(i).SourceText)
        s2 = Trim(trnlst.String(i).Text)
        If (s1 <> "" Or s2 <> "") Then
          ResourceName = trnlst.String(i).Resource.Type & " " & trnlst.String(i).Resource.ID

		  s = Refine(title) & Chr(9) & Refine(ResourceName) & Chr(9) & Refine(Str(trnlst.String(i).Number)) & Chr(9)
		  If trnlst.String(i).IDName = "" Then
			s = s & Refine(CStr(trnlst.String(i).ID))
 		  Else
			s = s & Refine(CStr(trnlst.String(i).IDName))
          End If
		  s = s & Chr(9) & Refine(trnlst.String(i).SourceText) & Chr(9) & Refine(trnlst.String(i).Text)

		  '### Additional Fields
		  Comment   = Refine(trnlst.String(i).Comment)
		  TransDate = trnlst.String(i).DateTranslated

     	  s = s & Chr(9) & Comment
		  s = s & Chr(9) & Month(TransDate) & "/" & Day(TransDate) & "/" & Year(TransDate)



          If trnlst.String(i).State(pslStateReadOnly) Then
			s = s & Chr(9) & "Locked"
          ElseIf trnlst.String(i).State(pslStateReview) Then
			s = s & Chr(9) & "Review"
          ElseIf Not trnlst.String(i).State(pslStateTranslated) Then
			s = s & Chr(9) & "Not Translated"
          ElseIf trnlst.String(i).State(pslStateBookmark) Then
			s = s & Chr(9) & "Bookmark"
          End If

          myfile.WriteLine s
        End If
      Next i
    Next

  myfile.Close
End Sub

Private Function Refine(s As String) As String
  Dim ss As String

  ss = Trim(s)
  ss = Replace(ss, Chr(10), "\n")
  ss = Replace(ss, Chr(13), "\r")
  ss = Replace(ss, Chr(9), "\t")
  ss = Replace(ss, """", """""")
  Refine = ss
End Function

Private Function GetTitle(path As String) As String
  Dim s As String, ss As String
  Dim n As Integer

  s = Trim(path)
  Do
    n = InStr(s, "\")
    If n < 1 Then
      Exit Do
    End If
    s = Mid(s, n + 1)
  Loop
  n = InStr(s, ".")
  If n < 1 Then
    ss = s
    s = ""
  End If
  Do Until s = ""
    n = InStr(s, ".")
    If n < 1 Then
      Exit Do
    End If
    If ss = "" Then
      ss = Left(s, n - 1)
    Else
      ss = ss & "." & Left(s, n - 1)
    End If
    s = Mid(s, n + 1)
  Loop
  GetTitle = ss
End Function
