Attribute VB_Name = "SerialPort"
'-------------------------------------------------------------------------------
Option Explicit

' This module is used to transfer data to and from the serial port.

Private Const InputBufferSize As Integer = 13   ' 4-byte buffer.
Private Const OutputBufferSize As Integer = 10  ' 1-byte buffer.

Private InputBuffer(1 To InputBufferSize) As Byte
Private OutputBuffer(1 To OutputBufferSize) As Byte

Private Const ASCII_LF     As Byte = 10
Private Const ASCII_CR     As Byte = 13
Private Const ASCIIplus    As Byte = 43
Private Const ASCIIminus   As Byte = 45
Private Const ASCIIdecimal As Byte = 46
Private Const ASCIIzero    As Byte = 48
'-------------------------------------------------------------------------------
Public Sub OpenSerialPort( _
    ByVal PortNumber As Byte, _
    ByVal BaudRate As Long)

' Opens a serial port at the specified baud rate.

    ' Com1 requires that the network be disabled. On the BasicX-01
    ' Developer Board, it may be necessary to raise pin 14, which can be
    ' done here or in the chip I/O initialization.
    '>>If (PortNumber = 1) Then
    '>>    Call PutPin(14, bxOutputHigh)
    '>>End If

    Call OpenQueue(InputBuffer, InputBufferSize)

    Call OpenQueue(OutputBuffer, OutputBufferSize)

    Call OpenCom(PortNumber, BaudRate, InputBuffer, OutputBuffer)

End Sub
'-------------------------------------------------------------------------------
Public Sub PutByte( _
    ByVal Value As Byte)

' Sends one byte of binary data to the serial port. The byte is sent
' directly without translating it to a string.

    Call PutQueue(OutputBuffer, Value, 1)

End Sub
'-------------------------------------------------------------------------------
Public Sub GetByte( _
    ByRef Value As Byte, _
    ByRef Success As Boolean)

' Inputs a byte from the serial port, if available. Returns regardless.  The
' Success flag is set depending on whether a byte is available.
'
' The byte is in direct binary format -- it is not in string format.

    ' Find out if anything is in the queue.
    Success = StatusQueue(InputBuffer)

    ' If data is in the queue, extract it.
    If (Success) Then
        Call GetQueue(InputBuffer, Value, 1)
    Else
        Value = 0
    End If

End Sub
'-------------------------------------------------------------------------------
Public Sub NewLine()

' Outputs a <CR> <LF> to the serial port.

    Call PutByte(ASCII_CR)
    Call PutByte(ASCII_LF)

End Sub
'-------------------------------------------------------------------------------
Public Sub PutLine( _
    ByRef Tx As String)

' Outputs a String type, followed by <CR> <LF>. Output is to the serial
' port.
    
    Call PutStr(Tx)
    
    Call NewLine

End Sub
'-------------------------------------------------------------------------------
Public Sub PutStr( _
    ByRef Tx As String)

' Outputs a String type to the serial port.

    Dim Length As Integer, Ch As String * 1, bCh As Byte
    Dim I As Integer

    Length = Len(Tx)

    For I = 1 To Length
        Ch = Mid(Tx, I, 1)
        bCh = Asc(Ch)
        Call PutByte(bCh)
    Next

End Sub
'-------------------------------------------------------------------------------
Public Sub PutB( _
    ByVal Value As Byte)

' Outputs a Byte type to the serial port.

    Dim Digit(1 To 3) As Byte
    Dim i As Integer, NDigits As Integer
    Const Base As Byte = 10

    NDigits = 0

    Do
        NDigits = NDigits + 1
        Digit(NDigits) = Value Mod Base
        Value = Value \ Base
    Loop Until (Value = 0)

    For i = NDigits To 1 Step -1
        Call PutByte(Digit(i) + ASCIIzero)
    Next

End Sub
'-------------------------------------------------------------------------------
Public Sub PutHexB( _
    ByVal Value As Byte)

' Outputs a Byte type to the serial port. Hexadecimal format is used.

    Dim Digit(1 To 2) As Byte, D As Byte
    Dim i As Integer, NDigits As Integer
    Const Base As Byte = 16
    Const ASCIIhexBias As Byte = 55

    NDigits = 0

    Do
        NDigits = NDigits + 1

        D = Value Mod Base
        If (D < 10) Then
            D = D + ASCIIzero
        Else
            D = D + ASCIIhexBias
        End If

        Digit(NDigits) = D

        Value = Value \ Base
    Loop Until (Value = 0)

    For i = NDigits To 1 Step -1
        Call PutByte(Digit(i))
    Next

End Sub
'-------------------------------------------------------------------------------
Public Sub PutI( _
    ByVal Value As Integer)

' Outputs an Integer type to the serial port.

    Call PutL(CLng(Value))

End Sub
'-------------------------------------------------------------------------------
Public Sub PutUI( _
    ByVal Value As UnsignedInteger)

' Outputs an UnsignedInteger type to the serial port.

    Dim L As Long, Tmp As New UnsignedInteger

    Tmp = Value

    L = 0

    ' Copy Value into the lower two bytes of L.
    Call BlockMove(2, MemAddress(Tmp), MemAddress(L))

    Call PutL(L)

End Sub
'-------------------------------------------------------------------------------
Public Sub PutUL( _
    ByVal Value As UnsignedLong)

' Outputs an UnsignedLong type to the serial port.

    Dim UL As New UnsignedLong, L As Long, Digit As New UnsignedLong
    Dim I As Integer, Temp As New UnsignedLong

    ' If the top bit is clear, the number is ready to go.
    If ((Value And &H80000000) = 0) Then
        Call PutL(CLng(Value))
        Exit Sub
    End If

    ' Divide by 10 is done by a right shift followed by a divide by 5.
    ' First clear top bit so we can do a signed divide.
    UL = Value
    UL = UL And &H7FFFFFFF

    ' Shift to the right 1 bit.
    L = CLng(UL)
    L = L \ 2

    ' Put the top bit back, except shifted to the right 1 bit.
    UL = CuLng(L)
    UL = UL Or &H40000000

    ' The number now fits in a signed long.
    L = CLng(UL)

    L = L \ 5

    Call PutL(L)

    ' Multiply by 10. Since multiply is not implemented for UnsignedLong, we
    ' do the equivalent addition.
    Temp = CuLng(L)
    UL = 0
    For I = 1 To 10
        UL = UL + Temp
    Next

    ' Find the rightmost digit.
    Digit = Value - UL
    Call PutL(CLng(Digit))

End Sub
'-------------------------------------------------------------------------------
Public Sub PutL( _
    ByVal Value As Long)

' Outputs a Long type to the serial port.
    
    ' Reserve space for "2147483648".
    Dim Digit(1 To 10) As Byte
    Dim NDigits As Integer
    Dim i As Integer
    Const Base As Long = 10

    ' The working number must be zero or negative. Otherwise the negative
    ' limit will cause overflow if we take its absolute value.
    If (Value < 0) Then
        Call PutByte(ASCIIminus)
    Else
        Value = -Value
    End If

    NDigits = 0

    Do
        NDigits = NDigits + 1
        Digit(NDigits) = CByte( Abs(Value Mod Base) )
        Value = Value \ Base
    Loop Until (Value = 0)

    ' Digits are stored in reverse order of display.
    For i = NDigits To 1 Step -1
        Call PutByte(Digit(i) + ASCIIzero)
    Next

End Sub
'-------------------------------------------------------------------------------
Public Sub PutSci( _
    ByVal Value As Single)

' Outputs floating point number in scientific notation format. The format
' is such that 13 characters are always generated. Sign characters are
' included for both mantissa and exponent. Exponents have 2 digits,
' including a leading zero if necessary.
'
' Example Formats:  "+1.234567E+00"
'                   "-7.654321E-20"
'                   "+3.141593E+05"
'                   "+0.000000E+00"

    Dim Mantissa As Single, Exponent As Integer, LMant As Long

    Call SplitFloat(Value, Mantissa, Exponent)

    ' Sign.
    If (Mantissa < 0.0) Then
        Call PutByte(ASCIIminus)
    Else
        Call PutByte(ASCIIplus)
    End If

    ' Convert mantissa to a 7-digit integer.
    LMant = FixL((Abs(Mantissa) * 1000000.0) + 0.5)

    ' Correct for roundoff error. Mantissa can't be > 9.999999
    If (LMant > 9999999) Then
        LMant = 9999999
    End If

    ' First digit of mantissa.
    Call PutByte( CByte(LMant \ 1000000) + ASCIIzero)

    ' Decimal point.
    Call PutByte(ASCIIdecimal)

    ' Remaining digits of mantissa.
    LMant = LMant Mod 1000000
    
    Call InsertZeros(LMant)
    
    Call PutL(LMant)

    ' Exponent.
    Call PutByte(69)  ' E

    If (Exponent < 0) Then
        Call PutByte(ASCIIminus)
    Else
        Call PutByte(ASCIIplus)
    End If

    ' A 2-digit exponent has a leading zero.
    If (Abs(Exponent) < 10) Then
        Call PutByte(ASCIIzero)
    End If

    Call PutI(Abs(Exponent))

End Sub
'-------------------------------------------------------------------------------
Private Sub InsertZeros( _
    ByVal X As Long)
    
    Dim NumZeros As Byte, I As Byte

    If (X >= 100000) Then
        Exit Sub                ' 100 000 <= X
    ElseIf (X >= 10000) Then
        NumZeros = 1            '  10 000 <= X <= 99 999
    ElseIf (X >= 1000) Then
        NumZeros = 2            '   1 000 <= X <=  9 999
    ElseIf (X >= 100) Then
        NumZeros = 3            '     100 <= X <=    999
    ElseIf (X >= 10) Then
        NumZeros = 4            '      10 <= X <=     99
    Else
        NumZeros = 5            '       0 <= X <=      9
    End If
    
    For I = 1 To NumZeros
        Call PutByte(ASCIIzero)
    Next
    
End Sub
'-------------------------------------------------------------------------------
Public Sub PutS( _
    ByVal Value As Single)

' Outputs a floating point number to the serial port. If the number can be
' displayed without using scientific notation, it is. Otherwise scientific
' notation is used.

    Dim X As Single, DecimalPlace As Integer, Mantissa As Single
    Dim Exponent As Integer, DigitPosition As Integer, Factor As Long
    Dim LMant As Long, DecimalHasDisplayed As Boolean

    ' Special case for zero.
    If (Value = 0.0) Then
        Call PutByte(ASCIIzero)
        Call PutByte(ASCIIdecimal)
        Call PutByte(ASCIIzero)
        Exit Sub
    End If

    X = Abs(Value)

    ' Use scientific notation for values too big or too small.
    If (X < 0.1) Or (X > 999999.9) Then
        Call PutSci(Value)
        Exit Sub
    End If

    ' What follows is non-exponent displays for 0.1000000 < Value < 999999.9

    ' Sign.
    If (Value < 0.0) Then
        Call PutByte(ASCIIminus)
    End If

    If (X < 1.0) Then
        Call PutByte(ASCIIzero)    ' Leading zero.
        Call PutByte(ASCIIdecimal)
        DecimalHasDisplayed = True
        DecimalPlace = 0
        
        ' Convert number to a 7-digit integer.
        LMant = FixL((X * 10000000.0) + 0.5)
    Else
        Call SplitFloat(X, Mantissa, Exponent)
        DecimalPlace = Exponent + 2

        ' Convert mantissa to a 7-digit integer.
        LMant = FixL((Abs(Mantissa) * 1000000.0) + 0.5)

        ' Correct for roundoff error. Mantissa can't be > 9.999999
        If (LMant > 9999999) Then
            LMant = 9999999
        End If
    
        DecimalHasDisplayed = False
    End If

    Factor = 1000000
    
    For DigitPosition = 1 To 7
        
        If (DigitPosition = DecimalPlace) Then
            Call PutByte(ASCIIdecimal)
            DecimalHasDisplayed = True
        End If
    
        Call PutByte( CByte(LMant \ Factor) + ASCIIzero )
        
        LMant = LMant Mod Factor
        
        ' Stop trailing zeros, except for one immediately following the
        ' decimal place.
        If (LMant = 0) Then
            If (DecimalHasDisplayed) Then
                Exit Sub
            End If
        End If
        
        Factor = Factor \ 10
    Next

End Sub
'-------------------------------------------------------------------------------
Private Sub SplitFloat( _
    ByVal Value As Single, _
    ByRef Mantissa As Single, _
    ByRef Exponent As Integer)

' Splits a floating point number into mantissa and exponent. The mantissa
' range is such that 1.0 <= Abs(Mantissa) < 10.0 for nonzero numbers, and
' zero otherwise.

    Dim X As Single, Factor As Single

    ' Zero is a special case.
    If (Value = 0.0) Then
        Mantissa = 0.0
        Exponent = 0
        Exit Sub
    End If

    X = Abs(Value)

    Exponent = 0
    Factor = 1.0

    ' Multiply or divide by ten to transform number to value between 1 and 10.
    Do
        If (X >= 10.0) Then
            X = X / 10.0
            Factor = Factor * 10.0
            Exponent = Exponent + 1
        ElseIf (X < 1.0) Then
            X = X * 10.0
            Factor = Factor * 10.0
            Exponent = Exponent - 1
        Else
            ' When we reach this point, then 1.0 <= mantissa < 10.0.
            Exit Do
        End If
    Loop

    ' Determine mantissa.
    If (Exponent = 0) Then
        Mantissa = Value
    ElseIf (Exponent > 0) Then
        Mantissa = Value / Factor
    Else
        Mantissa = Value * Factor
    End If
            
End Sub
'-------------------------------------------------------------------------------
