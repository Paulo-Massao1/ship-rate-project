from __future__ import annotations

import calendar
import csv
import datetime as dt
import json
import re
from collections import defaultdict
from pathlib import Path

import pdfplumber


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets" / "tide_data_source"
OUTPUT_DIR = ROOT / "assets" / "tide_data"
YEAR = 2026

TABLE_PAGES = [
    [1, 2, 3, 4],
    [5, 6, 7, 8],
    [9, 10, 11, 12],
]

WEEKDAYS = {"SEG", "TER", "QUA", "QUI", "SEX", "SAB", "SÁB", "DOM"}

LOCATIONS = {
    "curua": {
        "file": "curua.json",
        "location": "Igarapé Grande do Curuá",
        "latitude": "00° 45'.8 N",
        "longitude": "50° 07'.1 W",
        "timezone": "UTC -03:00",
        "meanLevel": 2.52,
        "parser": "table_pdf",
    },
    "santana": {
        "file": "santana.json",
        "location": "Porto de Santana",
        "latitude": "00° 03'.7 S",
        "longitude": "51° 10'.1 W",
        "timezone": "UTC -03:00",
        "meanLevel": 1.65,
        "parser": "table_pdf",
    },
    "breves": {
        "file": "breves.json",
        "location": "Atracadouro de Breves",
        "latitude": "01° 41'.5 S",
        "longitude": "50° 29' W",
        "timezone": "UTC -03:00",
        "meanLevel": 0.36,
        "parser": "table_pdf",
    },
    "arco_lamoso": {
        "file": "arco_lamoso.json",
        "location": "Barra Norte - Arco Lamoso",
        "latitude": "01° 26'.1 N",
        "longitude": "49° 13'.3 W",
        "timezone": "UTC -03:00",
        "meanLevel": 1.9,
        "parser": "table_pdf",
    },
    "pem15": {
        "file": "pem15.json",
        "location": "PEM 15",
        "latitude": "",
        "longitude": "",
        "timezone": "UTC -03:00",
        "meanLevel": 2.0,
        "parser": "pem15",
    },
}


def plain_text(path: Path) -> str:
    if path.suffix.lower() == ".pdf":
        with pdfplumber.open(path) as pdf:
            return "\n".join(page.extract_text() or "" for page in pdf.pages[:2])
    return path.read_text(encoding="utf-8-sig", errors="replace")


def identify_source(path: Path) -> str:
    text = f"{path.name}\n{plain_text(path)}".upper()
    if "PEM15" in text or "PEM 15" in text:
        return "pem15"
    if "PORTO DE SANTANA" in text:
        return "santana"
    if "ATRACADOURO DE BREVES" in text:
        return "breves"
    if "BARRA NORTE" in text and "ARCO LAMOSO" in text:
        return "arco_lamoso"
    if "IGARAP" in text and "CURU" in text:
        return "curua"
    raise ValueError(f"Could not identify tide source: {path}")


def is_time(token: str) -> bool:
    return bool(re.fullmatch(r"\d{4}", token)) and 0 <= int(token[:2]) <= 23 and 0 <= int(token[2:]) <= 59


def is_height(token: str) -> bool:
    return bool(re.fullmatch(r"-?\d+[.,]\d+", token))


def normalize_weekday(token: str) -> str:
    return token.upper().replace("�", "A")


def column_bounds(words: list[dict], page_width: float) -> list[float]:
    header_positions = sorted(
        word["x0"]
        for word in words
        if word["text"] == "HORA" and 95 <= word["top"] <= 110
    )
    if len(header_positions) != 8:
        raise ValueError(f"Expected 8 HORA headers, found {len(header_positions)}")
    middle_points = [
        (left + right) / 2 for left, right in zip(header_positions, header_positions[1:])
    ]
    return [0, *middle_points, page_width + 1]


def rows_for_column(words: list[dict], bounds: list[float], column: int) -> list[list[str]]:
    left, right = bounds[column], bounds[column + 1]
    column_words = [
        word
        for word in words
        if word["top"] > 105 and left <= word["x0"] < right
    ]
    column_words.sort(key=lambda word: (word["top"], word["x0"]))

    rows: list[list[dict]] = []
    for word in column_words:
        if not rows or abs(rows[-1][0]["top"] - word["top"]) > 4:
            rows.append([word])
        else:
            rows[-1].append(word)

    tokens_by_row: list[list[str]] = []
    for row in rows:
        row.sort(key=lambda word: word["x0"])
        tokens_by_row.append([word["text"] for word in row])
    return tokens_by_row


def parse_column(rows: list[list[str]], month: int) -> dict[str, list[dict]]:
    parsed: dict[str, list[dict]] = {}
    current_day: int | None = None
    current_entries: list[dict] = []
    pending_time: str | None = None
    month_days = calendar.monthrange(YEAR, month)[1]

    def flush_day() -> None:
        if current_day is None:
            return
        date = dt.date(YEAR, month, current_day).isoformat()
        parsed[date] = sorted(current_entries, key=lambda item: item["time"])

    for row in rows:
        for token in row:
            if normalize_weekday(token) in WEEKDAYS:
                continue
            if re.fullmatch(r"\d{1,2}", token) and 1 <= int(token) <= month_days:
                flush_day()
                current_day = int(token)
                current_entries = []
                pending_time = None
                continue
            if is_time(token):
                pending_time = f"{token[:2]}:{token[2:]}"
                continue
            if is_height(token) and current_day is not None and pending_time is not None:
                current_entries.append(
                    {
                        "time": pending_time,
                        "height": float(token.replace(",", ".")),
                    }
                )
                pending_time = None

    flush_day()
    return parsed


def parse_table_pdf(path: Path) -> dict[str, list[dict]]:
    data: dict[str, list[dict]] = {}
    with pdfplumber.open(path) as pdf:
        for page_index, months in enumerate(TABLE_PAGES):
            page = pdf.pages[page_index]
            words = page.extract_words(x_tolerance=2, y_tolerance=3)
            bounds = column_bounds(words, page.width)
            for column in range(8):
                month = months[column // 2]
                rows = rows_for_column(words, bounds, column)
                data.update(parse_column(rows, month))
    return data


def parse_pem15_pdf(path: Path) -> dict[str, list[dict]]:
    pattern = re.compile(r"\b(\d{2})/(\d{2})/(\d{2})\s+(\d{2}):(\d{2})\s+(-?\d+[,.]\d+)\b")
    data: dict[str, list[dict]] = defaultdict(list)
    with pdfplumber.open(path) as pdf:
        text = "\n".join(page.extract_text() or "" for page in pdf.pages)
    for day, month, year, hour, minute, height in pattern.findall(text):
        full_year = 2000 + int(year)
        if full_year != YEAR:
            continue
        date = dt.date(full_year, int(month), int(day)).isoformat()
        data[date].append(
            {
                "time": f"{hour}:{minute}",
                "height": float(height.replace(",", ".")),
            }
        )
    return {date: sorted(entries, key=lambda item: item["time"]) for date, entries in data.items()}


def parse_pem15_csv(path: Path) -> dict[str, list[dict]]:
    data: dict[str, list[dict]] = defaultdict(list)
    with path.open(encoding="utf-8-sig", newline="") as csvfile:
        sample = csvfile.read(2048)
        csvfile.seek(0)
        dialect = csv.Sniffer().sniff(sample, delimiters=",;")
        reader = csv.DictReader(csvfile, dialect=dialect)
        for row in reader:
            values = {key.lower().strip(): value.strip() for key, value in row.items() if key}
            date_value = values.get("data") or values.get("date")
            time_value = values.get("hora") or values.get("time")
            height_value = values.get("nível") or values.get("nivel") or values.get("height")
            if not (date_value and time_value and height_value):
                continue
            day, month, year = re.split(r"[/-]", date_value)
            full_year = int(year) if len(year) == 4 else 2000 + int(year)
            if full_year != YEAR:
                continue
            date = dt.date(full_year, int(month), int(day)).isoformat()
            data[date].append(
                {
                    "time": time_value[:5],
                    "height": float(height_value.replace(",", ".")),
                }
            )
    return {date: sorted(entries, key=lambda item: item["time"]) for date, entries in data.items()}


def add_tide_types(data: dict[str, list[dict]], mean_level: float) -> dict[str, list[dict]]:
    typed: dict[str, list[dict]] = {}
    for date in sorted(data):
        typed[date] = [
            {
                "time": entry["time"],
                "height": entry["height"],
                "type": "preamar" if entry["height"] >= mean_level else "baixamar",
            }
            for entry in sorted(data[date], key=lambda item: item["time"])
        ]
    return typed


def expected_dates() -> list[str]:
    start = dt.date(YEAR, 1, 1)
    return [(start + dt.timedelta(days=offset)).isoformat() for offset in range(365)]


def validate(location_key: str, data: dict[str, list[dict]]) -> None:
    dates = expected_dates()
    missing = [date for date in dates if date not in data]
    if missing:
        raise ValueError(f"{location_key} is missing dates: {missing}")
    extra = [date for date in data if date not in dates]
    if extra:
        raise ValueError(f"{location_key} has unexpected dates: {extra}")
    # A few official DHN rows include secondary extrema, so keep up to 6 readings.
    bad_counts = {date: len(entries) for date, entries in data.items() if not 3 <= len(entries) <= 6}
    if bad_counts:
        raise ValueError(f"{location_key} has invalid entry counts: {bad_counts}")
    for date, entries in data.items():
        for entry in entries:
            if not re.fullmatch(r"\d{2}:\d{2}", entry["time"]):
                raise ValueError(f"{location_key} has invalid time at {date}: {entry}")
            if not isinstance(entry["height"], float):
                raise ValueError(f"{location_key} has non-numeric height at {date}: {entry}")
            if entry["type"] not in {"preamar", "baixamar"}:
                raise ValueError(f"{location_key} has invalid tide type at {date}: {entry}")


def parse_source(path: Path, location_key: str) -> dict[str, list[dict]]:
    parser = LOCATIONS[location_key]["parser"]
    if parser == "table_pdf":
        return parse_table_pdf(path)
    if path.suffix.lower() == ".csv":
        return parse_pem15_csv(path)
    return parse_pem15_pdf(path)


def write_location(location_key: str, path: Path) -> None:
    meta = LOCATIONS[location_key]
    data = parse_source(path, location_key)
    typed_data = add_tide_types(data, meta["meanLevel"])
    validate(location_key, typed_data)

    payload = {
        "location": meta["location"],
        "latitude": meta["latitude"],
        "longitude": meta["longitude"],
        "timezone": meta["timezone"],
        "meanLevel": meta["meanLevel"],
        "year": YEAR,
        "data": typed_data,
    }

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    output_path = OUTPUT_DIR / meta["file"]
    output_path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {output_path.relative_to(ROOT)} ({len(typed_data)} days)")


def main() -> None:
    sources = [path for path in SOURCE_DIR.iterdir() if path.is_file()]
    found: dict[str, Path] = {}
    for path in sources:
        location_key = identify_source(path)
        if location_key in found:
            raise ValueError(f"Duplicate source for {location_key}: {found[location_key]} and {path}")
        found[location_key] = path

    missing_sources = sorted(set(LOCATIONS) - set(found))
    if missing_sources:
        raise ValueError(f"Missing source files for: {missing_sources}")

    for location_key in ["santana", "arco_lamoso", "pem15", "curua", "breves"]:
        write_location(location_key, found[location_key])


if __name__ == "__main__":
    main()
