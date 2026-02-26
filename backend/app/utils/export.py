import csv
import io
from typing import List, Dict, Any
from fastapi.responses import StreamingResponse

def generate_csv_response(data: List[Dict[str, Any]], filename: str) -> StreamingResponse:
    """
    Generates a CSV file from a list of dictionaries and returns it as a StreamingResponse.
    """
    if not data:
        # Return empty CSV with headers if possible or just empty
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(["No data available"])
        output.seek(0)
        return StreamingResponse(
            output,
            media_type="text/csv",
            headers={"Content-Disposition": f"attachment; filename={filename}.csv"}
        )

    output = io.StringIO()
    # Use the keys from the first dictionary as headers
    headers = data[0].keys()
    writer = csv.DictWriter(output, fieldnames=headers)
    
    writer.writeheader()
    writer.writerows(data)
    
    output.seek(0)
    return StreamingResponse(
        output,
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}.csv"}
    )
