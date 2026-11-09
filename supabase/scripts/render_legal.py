"""Render Tilo's current legal sources; no network requests."""
from pathlib import Path
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib import colors
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from xml.sax.saxutils import escape
ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'docs/BackendAPI/legal'
font = Path('/System/Library/Fonts/Supplemental/Arial.ttf')
if font.exists():
    pdfmetrics.registerFont(TTFont('TiloText', str(font)))
styles = getSampleStyleSheet()
for name in ('Title', 'Heading2', 'BodyText'):
    styles[name].fontName = 'TiloText' if font.exists() else 'Helvetica'
styles['Title'].textColor = colors.HexColor('#C8643B')
styles['BodyText'].fontSize = 9.5
styles['BodyText'].leading = 13.5
styles['Heading2'].fontSize = 12
styles['Heading2'].spaceBefore = 8
styles['Heading2'].textColor = colors.HexColor('#1F352D')
def footer(canvas, doc):
    canvas.setFont('TiloText' if font.exists() else 'Helvetica', 8)
    canvas.setFillColor(colors.HexColor('#777777'))
    canvas.drawString(42, 25, f'Tilo | {doc.effective_date}')
    canvas.drawRightString(553, 25, str(doc.page))
for kind in ('terms', 'privacy'):
    flow = []
    source = (BASE / f'{kind}.md').read_text()
    for para in source.split('\n\n'):
        if para.startswith('# '):
            title, _, date = para.partition('\n')
            flow += [Paragraph(escape(title[2:]), styles['Title']), Paragraph(escape(date), styles['BodyText']), Spacer(1, 10)]
        elif para.startswith('## '):
            title, _, body = para.partition('\n')
            flow += [Paragraph(escape(title[3:]), styles['Heading2'])]
            if body: flow += [Paragraph(escape(body), styles['BodyText'])]
        else: flow += [Paragraph(escape(para.replace('\n',' ')), styles['BodyText']), Spacer(1, 5)]
    document = SimpleDocTemplate(str(BASE / f'{kind}.pdf'), pagesize=(595,842), leftMargin=42,rightMargin=42,topMargin=40,bottomMargin=45,title=f'Tilo {"Terms of Use" if kind=="terms" else "Privacy Policy"}',author='Tilo')
    document.effective_date = source.splitlines()[1]
    document.build(flow,onFirstPage=footer,onLaterPages=footer)
