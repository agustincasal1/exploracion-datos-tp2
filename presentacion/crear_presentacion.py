"""Regenera presentacion.pdf con las tablas y los gráficos producidos en R.

Herramienta opcional de armado del PDF. El análisis se ejecuta solamente en R.
Desde la raíz: python presentacion/crear_presentacion.py
Dependencias de esta herramienta: reportlab y pymupdf (fitz).
"""
from pathlib import Path
import csv
from html import escape
import io

import fitz
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import Paragraph, Table, TableStyle
from reportlab.lib.utils import ImageReader
from reportlab.graphics.shapes import Drawing, Rect, String, Line
from reportlab.graphics import renderPDF, renderSVG

RAIZ = Path(__file__).resolve().parent.parent
TABLAS = RAIZ / "salidas" / "resultados"
FUENTES = Path("C:/Windows/Fonts")
if (FUENTES / "arial.ttf").exists():
    pdfmetrics.registerFont(TTFont("Texto", str(FUENTES / "arial.ttf")))
    pdfmetrics.registerFont(TTFont("Negrita", str(FUENTES / "arialbd.ttf")))
else:
    # Deja el armado disponible también en otros sistemas con fuentes PDF base.
    pdfmetrics.registerFont(pdfmetrics.Font("Texto", "Helvetica", "WinAnsiEncoding"))
    pdfmetrics.registerFont(pdfmetrics.Font("Negrita", "Helvetica-Bold", "WinAnsiEncoding"))

AZUL = colors.HexColor("#234C66")
TINTA = colors.HexColor("#202A31")
GRIS = colors.HexColor("#52606A")
CLARO = colors.HexColor("#E3E9ED")
W, H = 1280, 720


def leer(nombre):
    with (TABLAS / nombre).open(encoding="utf-8-sig", newline="") as archivo:
        return list(csv.DictReader(archivo))


def numero(valor, decimales=0):
    return f"{float(valor):,.{decimales}f}".replace(",", "@").replace(".", ",").replace("@", ".")


def modelo():
    """Diagrama de datos editable en SVG, con claves, atributos y relaciones."""
    d = Drawing(1140, 460)

    def entidad(x, y, ancho, titulo, campos):
        alto = 48 + 29 * len(campos)
        d.add(Rect(x, y, ancho, alto, fillColor=colors.white, strokeColor=AZUL, strokeWidth=1.5))
        d.add(Line(x, y + alto - 42, x + ancho, y + alto - 42, strokeColor=AZUL))
        d.add(String(x + 14, y + alto - 29, titulo, fontName="Negrita", fontSize=23, fillColor=AZUL))
        for i, campo in enumerate(campos):
            d.add(String(x + 14, y + alto - 68 - i * 29, campo, fontName="Texto", fontSize=18, fillColor=TINTA))

    entidad(0, 310, 240, "paises", ["PK pais_id", "UK pais"])
    entidad(350, 210, 300, "facturas", ["PK factura", "cliente_id (NULL permitido)", "FK pais_id", "cancelacion (0/1)"])
    entidad(350, 0, 300, "articulos", ["PK codigo", "descripcion (NULL permitido)", "fila_descripcion (origen)"])
    entidad(770, 100, 365, "lineas", ["PK fila_excel", "FK factura", "FK codigo", "fecha_hora", "cantidad",
                                                  "precio_peniques", "descripcion_original", "analizable (0/1)"])
    for x1, y1, x2, y2, etiqueta in [(240, 360, 350, 360, "1 a N"),
                                    (650, 315, 770, 315, "1 a N"),
                                    (650, 110, 710, 110, "1 a N")]:
        d.add(Line(x1, y1, x2, y2, strokeColor=AZUL, strokeWidth=2))
        d.add(String(x1 + 20, y1 + 12, etiqueta, fontName="Texto", fontSize=18, fillColor=TINTA))
    d.add(Line(710, 110, 710, 240, strokeColor=AZUL, strokeWidth=2))
    d.add(Line(710, 240, 770, 240, strokeColor=AZUL, strokeWidth=2))
    renderSVG.drawToFile(d, str(RAIZ / "docs" / "modelo_relacional.svg"))
    documento = fitz.open(stream=renderPDF.drawToString(d), filetype="pdf")
    documento[0].get_pixmap(matrix=fitz.Matrix(1.5, 1.5)).save(str(RAIZ / "docs" / "modelo_relacional.png"))
    return d


def parrafo(c, texto, x, y, ancho=1140, size=27, color=TINTA, negrita=False):
    estilo = ParagraphStyle("texto", fontName="Negrita" if negrita else "Texto", fontSize=size,
                            leading=size * 1.3, textColor=color)
    p = Paragraph(texto, estilo)
    _, alto = p.wrap(ancho, H)
    p.drawOn(c, x, y - alto)
    return y - alto


def tabla(c, filas, anchos, y=550, size=23):
    estilo = ParagraphStyle("celda", fontName="Texto", fontSize=size, leading=size * 1.25, textColor=TINTA)
    contenido = [[Paragraph(escape(str(v)), estilo) for v in fila] for fila in filas]
    t = Table(contenido, colWidths=anchos)
    t.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("BACKGROUND", (0, 0), (-1, 0), CLARO),
        ("LINEBELOW", (0, 0), (-1, 0), 1.3, AZUL),
        ("LINEBELOW", (0, 1), (-1, -1), 0.5, CLARO),
        ("LEFTPADDING", (0, 0), (-1, -1), 12),
        ("RIGHTPADDING", (0, 0), (-1, -1), 12),
        ("TOPPADDING", (0, 0), (-1, -1), 12),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 12),
    ]))
    _, alto = t.wrap(W - 140, H)
    if y - alto < 85:
        raise ValueError("La tabla no cabe en la diapositiva")
    t.drawOn(c, 70, y - alto)


def main():
    diagrama = modelo()
    mensual = leer("mensual.csv")
    paises = leer("paises.csv")
    articulos = leer("articulos.csv")
    calidad = leer("calidad.csv")[0]
    problemas = {f["indicador"]: f["cantidad"] for f in leer("problemas_iniciales.csv")}
    with (RAIZ / "datos" / "procedencia.csv").open(encoding="utf-8-sig") as f:
        acceso = next(csv.DictReader(f))["registrado_utc"].split()[0]
    c = canvas.Canvas(str(RAIZ / "presentacion.pdf"), pagesize=(W, H))
    c.setTitle("Una tienda online: ventas, países y cancelaciones")
    c.setAuthor("Agustín Casal")
    pagina = 0

    def empezar(titulo):
        nonlocal pagina
        pagina += 1
        if pagina > 1:
            c.showPage()
        c.setFillColor(colors.white)
        c.rect(0, 0, W, H, fill=1, stroke=0)
        parrafo(c, titulo, 70, 657, size=40, color=AZUL, negrita=True)
        c.setFont("Texto", 16)
        c.setFillColor(GRIS)
        c.drawString(70, 25, "Agustín Casal - Exploración de Datos - UCA Rosario")
        c.drawRightString(W - 70, 25, str(pagina))

    empezar("¿Qué vende una tienda online y cuánto cancela?")
    parrafo(c, "Quiero comparar las ventas registradas por mes, por país y por artículo, teniendo en cuenta las cancelaciones.",
            70, 480, 1030, 35)
    parrafo(c, "Elegí el tema por mi interés en el negocio online y mi vínculo con OnCloud. Los datos son públicos y pertenecen a otra empresa.",
            70, 310, 1040, 27)
    parrafo(c, "TP2 individual. Primer trimestre de 2011. Una tienda británica.", 70, 150, size=25, color=GRIS)

    empezar("Las preguntas del trabajo")
    y = 530
    for texto in ["1. ¿Cómo cambian los importes de ventas y cancelaciones entre enero y marzo?",
                  "2. ¿Qué países concentran el importe neto registrado?",
                  "3. ¿Qué artículos tienen más unidades netas registradas?"]:
        y = parrafo(c, texto, 70, y, size=31) - 40
    parrafo(c, "El análisis puede ayudar a decidir qué operaciones revisar con más detalle. No alcanza para recomendar stock o explicar por qué compran los clientes.",
            70, 205, size=25, color=GRIS)

    empezar("Fuente y selección")
    tabla(c, [["Fuente", "Elección y alcance"],
              ["Online Retail / UCI", "Daqing Chen. Archivo Excel público con ocho columnas. Licencia CC BY 4.0."],
              ["Original conservado", "541.909 renglones. Se guarda sin editar y se verifica su huella MD5."],
              ["Selección", "Enero a marzo de 2011, todos los países. 99.602 renglones, 31 países."],
              ["Por qué sirve", "Tiene números de factura, códigos de artículo, cantidades, precios y países para relacionar."],
              ["Fiabilidad y límite", "Responsable, DOI y documentación identificables. Tienda anonimizada y datos históricos."]],
          [285, 855], size=23)
    parrafo(c, f"Fuente: archive.ics.uci.edu/dataset/352/online+retail. DOI 10.24432/C5BW33. Acceso: {acceso}.",
            70, 80, size=18, color=GRIS)

    empezar("Qué representa una fila")
    parrafo(c, "Una fila es un renglón de una factura. La cantidad puede ser negativa y el precio está en libras esterlinas (GBP).", 70, 545, size=28)
    tabla(c, [["Fila Excel / factura", "Cantidad", "Precio", "Importe"],
              ["61621 / 541431", "74.215", "1,04 GBP", "+77.183,60 GBP"],
              ["61626 / C541433", "-74.215", "1,04 GBP", "-77.183,60 GBP"]],
          [410, 200, 230, 300], y=410, size=25)
    parrafo(c, "Las dos operaciones están separadas por dieciséis minutos. Conservar ambas evita confundir ventas positivas con importe neto.", 70, 190, size=26)
    parrafo(c, "C inicial indica cancelación según UCI. La fuente no permite asegurar que haya una devolución física.", 70, 95, size=21, color=GRIS)

    empezar("Diagnóstico antes de preparar")
    tabla(c, [["Lo que aparece", "Cantidad", "Decisión"],
              ["Cliente sin identificar", numero(calidad["sin_cliente"]), "Conservar el renglón y dejar el cliente como NULL."],
              ["Descripción ausente", "344", "No inventar el nombre del artículo."],
              ["Precio cero", numero(calidad["precio_cero"]), "Guardar en la base y separar del análisis de ventas."],
              ["Renglones idénticos a otros", "784", "Conservar y medir el efecto de quitarlos."],
              ["Descripciones con espacios en bordes", numero(problemas["descripcion_con_espacios_en_bordes"]), "Normalizar la etiqueta y guardar el texto original."],
              ["Facturas con horas distintas", "22", "Guardar la hora en cada línea."]], [415, 155, 570], size=22)
    parrafo(c, "El 29,62 % de los renglones no tiene cliente identificado. Eso limita el estudio de clientes, pero no impide sumar importes.", 70, 82, size=21, color=GRIS)

    empezar("Cuatro tablas que se relacionan")
    renderPDF.draw(diagrama, c, 70, 130)
    parrafo(c, "PK: clave primaria. FK: clave foránea. UK: valor único. Cada línea conserva la fila del Excel como vínculo con el original.",
            70, 103, size=21, color=GRIS)
    parrafo(c, "Los cuatro dataframes salen del Excel. El código define las reglas y las claves de país.",
            70, 595, size=24)

    empezar("Preparación y comparación")
    tabla(c, [["Regla", "Resultado"],
              ["Fecha y hora por línea", "99.602 fechas guardadas en texto ISO, sin convertirlas a la hora argentina."],
              ["Precio en peniques", "99.602 precios multiplicados por 100. Sin pérdida de decimales en esta selección."],
              ["Etiqueta de artículo", "18.571 textos normalizados. Se conserva la descripción recibida y la fila de la etiqueta elegida."],
              ["Precio cero", "513 renglones separados de los resultados, todos conservados en SQLite."],
              ["Antes / después", "99.602 renglones en ambos casos. 99.089 renglones entran en los tres resultados."]], [375, 765], size=23)
    parrafo(c, "La bitácora registra condición, motivo, acción y afectados. La carga se confirma junta mediante una transacción.", 70, 83, size=22, color=GRIS)

    empezar("Consultas a la base")
    parrafo(c, "Las ocho consultas están guardadas en SQL. Las tres principales agrupan por mes, país y artículo. Los gráficos parten de esos resultados.", 70, 545, size=29)
    codigo = ["SELECT p.pais,", "       SUM(l.cantidad*l.precio_peniques)/100.0 AS neto_gbp",
              "FROM lineas l JOIN facturas f ON l.factura=f.factura",
              "JOIN paises p ON f.pais_id=p.pais_id", "WHERE l.analizable=1", "GROUP BY p.pais", "ORDER BY neto_gbp DESC;"]
    c.setFillColor(TINTA)
    c.setFont("Courier", 22)
    for i, linea in enumerate(codigo):
        c.drawString(90, 385 - 33 * i, linea)
    parrafo(c, "Cada fila devuelve un país. El JOIN enlaza por claves. Otro control utiliza las cuatro tablas y verifica que no se multipliquen líneas ni dinero.",
            70, 120, size=23, color=GRIS)

    empezar("Comprobaciones del proceso")
    tabla(c, [["Prueba", "Evidencia esperada y obtenida"],
              ["Caso conocido", "74.215 × 104 = 7.718.360 peniques. La compra y su cancelación suman cero."],
              ["Casos separados", "Fecha imposible, NA, espacios, precio con tres decimales y cero."],
              ["Claves y relaciones", "Sin claves repetidas ni referencias obligatorias huérfanas. JOIN sin multiplicar importes."],
              ["Rollback", "Una inserción válida se revierte al fallar la siguiente por una factura inexistente."],
              ["Reconstrucción", "Una base nueva devuelve exactamente los mismos resultados en las ocho consultas."]], [325, 815], size=23)
    parrafo(c, "También se concilian las filas seleccionadas y separadas, se compara SQL contra R y se verifica que el original conserve su MD5.", 70, 120, size=22, color=GRIS)

    empezar("Límites de lo que puedo afirmar")
    textos = ["Los resultados describen una sola tienda británica en tres meses de 2011. Incluye compradores mayoristas.",
              "El neto es cantidad por precio registrado. No conozco costos ni información contable suficiente para hablar de ganancia.",
              "Una cancelación del trimestre puede corresponder a una compra anterior. No calculo una tasa de devolución por compra.",
              "Conservo las 784 repeticiones porque no puedo demostrar que sean errores. Si quitara las copias posteriores, el neto bajaría 3.841,04 GBP."]
    y = 550
    for texto in textos:
        y = parrafo(c, texto, 70, y, size=27) - 26
    parrafo(c, "Fuente: Chen (2015), Online Retail, UCI, CC BY 4.0. Código y documentación en el repositorio del TP2.", 70, 75, size=20, color=GRIS)

    def grafico(titulo, nombre, mensaje):
        empezar(titulo)
        imagen = ImageReader(str(TABLAS / nombre))
        iw, ih = imagen.getSize()
        escala = min(1140 / iw, 485 / ih)
        ancho, alto = iw * escala, ih * escala
        c.drawImage(imagen, (W - ancho) / 2, 115 + (485 - alto) / 2, ancho, alto, mask="auto")
        parrafo(c, mensaje, 70, 100, size=22)

    mayor = max(mensual, key=lambda x: float(x["neto_gbp"]))
    grafico("Marzo tiene el mayor neto del trimestre", "grafico_1_meses.png",
            f"Marzo: {numero(mayor['neto_gbp'], 2)} GBP netos. Enero concentra más cancelaciones. Tres meses no permiten afirmar una tendencia anual.")
    grafico("Reino Unido concentra el 80,5 % del neto", "grafico_2_paises.png",
            f"United Kingdom: {numero(paises[0]['neto_gbp'], 2)} GBP. El porcentaje usa el neto de los 31 países. Describe esta tienda, no el tamaño de cada mercado.")
    grafico("El código 85099B encabeza las unidades netas", "grafico_3_articulos.png",
            f"{numero(articulos[0]['unidades_netas'])} unidades netas de JUMBO BAG RED RETROSPOT. Las cantidades son unidades comerciales del código y no miden rentabilidad.")
    if pagina != 13:
        raise ValueError("Se esperaban trece diapositivas")
    c.save()
    print("Presentación creada: 13 diapositivas. Las tres últimas contienen los gráficos.")


if __name__ == "__main__":
    main()
